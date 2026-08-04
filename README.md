# Caution: Never upgrade this type of hand made version without consulting, version upgrade will break the database unless done with advised way.

# (Important) Take a fresh backup of the db that you want to upgrade. 

# Postgres + pgvector image for KubeDB

Custom Postgres `16.8` image with the [`pgvector`](https://github.com/pgvector/pgvector)
extension baked in.

| Image | pgvector |
|---|---|
| `souravbiswassanto/postgres:16.8-pgvector` | 0.8.1 |
| `souravbiswassanto/postgres:16.8-pgvector-0.8.4` | 0.8.4 |

> **Build your own** (optional — skip if you are using the images above):
> ```bash
> docker build -t <your-registry>/postgres:16.8-pgvector-0.8.4 .
> docker push  <your-registry>/postgres:16.8-pgvector-0.8.4
> ```
> Then substitute your image name for `spec.db.image` everywhere below.

Throughout this document, replace every `<>` placeholder with your own values:

```yaml
metadata:
  name: <>          # your Postgres object name
  namespace: <>     # your namespace
```

---

## 1. Test live on cluster

Run this **complete flow on a staging/test cluster first**. It creates a throwaway
database, loads vector data, upgrades pgvector in place, and verifies the result —
exactly the sequence you will later run against production.

### Step 1.1 — Create the `PostgresVersion` catalog

> **Skip this step if the `16.8-pgvector` PostgresVersion already exists** in your
> cluster. Check with `kubectl get pgversion 16.8-pgvector`. If it is there, do not
> re-apply it — jump to Step 1.2.

`example/catalog.yaml`:

```yaml
apiVersion: catalog.kubedb.com/v1alpha1
kind: PostgresVersion
metadata:
  name: 16.8-pgvector
spec:
  archiver:
    addon:
      name: postgres-addon
      tasks:
        fullBackup:
          name: physical-backup
        fullBackupRestore:
          name: physical-backup-restore
        manifestBackup:
          name: manifest-backup
        manifestRestore:
          name: manifest-restore
        volumeSnapshot:
          name: volume-snapshot
    walg:
      image: ghcr.io/kubedb/postgres-archiver:v0.19.0_16.1-alpine
  coordinator:
    image: ghcr.io/kubedb/pg-coordinator:v0.42.0
  db:
    baseOS: alpine
    image: souravbiswassanto/postgres:16.8-pgvector
  distribution: Official
  exporter:
    image: prometheuscommunity/postgres-exporter:v0.15.0
  initContainer:
    image: ghcr.io/kubedb/postgres-init:0.17.2
  podSecurityPolicies:
    databasePolicyName: ""
  securityContext:
    runAsAnyNonRoot: false
    runAsUser: 70
  stash:
    addon:
      backupTask:
        name: postgres-backup-16.1
      restoreTask:
        name: postgres-restore-16.1
  ui:
  - name: pgadmin
    version: v2024.4.27
  - name: dbgate
    version: v2024.4.27
  updateConstraints:
    allowlist:
    - '>= 16.8'
  version: "16.8"
```

```bash
kubectl apply -f example/catalog.yaml
kubectl get pgversion 16.8-pgvector -o yaml
```

### Step 1.2 — Create a test Postgres database

`example/demo.yaml`:

```yaml
apiVersion: kubedb.com/v1
kind: Postgres
metadata:
  name: <>
  namespace: <>
spec:
  version: 16.8-pgvector
  replicas: 1
  standbyMode: Hot
  storageType: Durable
  storage:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 10Gi
  deletionPolicy: WipeOut     # test database only — use Halt/DoNotTerminate in prod
```

```bash
kubectl apply -f example/demo.yaml

# wait until Ready
kubectl get pg -n <> <> -w
```

### Step 1.3 — Create the extension and load vector data

```bash
kubectl exec -i -n <> <>-0 -c postgres -- psql <<'EOF'
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS items (
  id        bigserial PRIMARY KEY,
  label     text,
  embedding vector(3)
);

INSERT INTO items (label, embedding) VALUES
  ('alpha',   '[1,2,3]'),
  ('beta',    '[4,5,6]'),
  ('gamma',   '[7,8,9]'),
  ('delta',   '[1,1,1]'),
  ('epsilon', '[0.5,0.25,0.75]');

CREATE INDEX IF NOT EXISTS items_embedding_hnsw
  ON items USING hnsw (embedding vector_l2_ops);

-- nearest neighbour query
SELECT label, embedding <-> '[3,3,3]' AS l2_distance
  FROM items ORDER BY embedding <-> '[3,3,3]' LIMIT 5;

-- record the starting version
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';
EOF
```

Expected: `vector | 0.8.1`.

> The extension name is **`vector`**, not `pgvector`. `CREATE EXTENSION pgvector;`
> will fail with *"extension \"pgvector\" is not available"*.

### Step 1.4 — Point the catalog at the pgvector `0.8.4` image

```bash
kubectl patch pgversion 16.8-pgvector --type=merge \
  -p '{"spec":{"db":{"image":"souravbiswassanto/postgres:16.8-pgvector-0.8.4"}}}'

kubectl get pgversion 16.8-pgvector -o jsonpath='{.spec.db.image}{"\n"}'
```

### Step 1.5 — Patch a label on the Postgres object to force a reconcile

Editing the `PostgresVersion` alone does not re-render the PetSet. Touching the
`Postgres` object wakes the provisioner, which then writes the new image into the
PetSet template:

```bash
kubectl patch pg -n <> <> --type=merge \
  -p '{"metadata":{"labels":{"pgvector-version":"v0-8-4"}}}'

# PetSet template should now show ...16.8-pgvector-0.8.4
kubectl get petset -n <> <> \
  -o jsonpath='{range .spec.template.spec.containers[*]}{.name}={.image}{"\n"}{end}'

# the running pod is still on the OLD image at this point — that is expected
kubectl get pod -n <> <>-0 -o jsonpath='{.spec.containers[0].image}{"\n"}'
```

### Step 1.6 — Restart the database

Restart the db pod. (Only works with standalone db)

Confirm the pod picked up the new image:

```bash
kubectl get pod -n <> <>-0 -o jsonpath='{.spec.containers[0].image}{"\n"}'
# souravbiswassanto/postgres:16.8-pgvector-0.8.4@sha256:...
```

### Step 1.7 — Adopt the new extension version inside the database

**This step is mandatory and easy to miss.** Swapping the image only replaces the
shared library and the `.control`/SQL files on disk. Each database keeps the
`vector` version it was created with until you explicitly update it:

```bash
kubectl exec -i -n <> <>-0 -c postgres -- psql <<'EOF'
SELECT name, default_version, installed_version
  FROM pg_available_extensions WHERE name = 'vector';
EOF
```

```
  name  | default_version | installed_version
--------+-----------------+-------------------
 vector | 0.8.4           | 0.8.1              <-- on disk 0.8.4, in DB still 0.8.1
```

Update it:

```bash
kubectl exec -i -n <> <>-0 -c postgres -- psql <<'EOF'
ALTER EXTENSION vector UPDATE;
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';
EOF
```

### Step 1.8 — Verify

```bash
kubectl exec -i -n <> <>-0 -c postgres -- psql <<'EOF'
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';
SELECT id, label, embedding FROM items ORDER BY id;
SELECT label, embedding <-> '[3,3,3]' AS l2_distance
  FROM items ORDER BY embedding <-> '[3,3,3]' LIMIT 5;
SELECT indexname FROM pg_indexes WHERE tablename = 'items';
EOF
```

Success criteria:

- [ ] `extversion` = `0.8.4`
- [ ] all 5 rows still present with correct embeddings
- [ ] distance query returns the same ordering as in Step 1.3
- [ ] `items_embedding_hnsw` index still listed

### Step 1.9 — Clean up the test database

```bash
kubectl delete -f restart.yaml
kubectl delete pg -n <> <>          # deletionPolicy: WipeOut removes the PVC too
```

---



---

## 2. Update an existing database

Use this section once Section 1 has passed on your test cluster. It assumes a
Postgres database is already running and you want to add or upgrade pgvector
**without recreating it**.

> Before you start: take a backup(**important**), and run this during a maintenance window. The
> database is restarted, so there is a short write outage (a few seconds of
> failover on HA clusters, a full restart on standalone).

Identify your target:

```bash
kubectl get pg -n <> <> -o custom-columns=\
NAME:.metadata.name,VERSION:.spec.version,STATUS:.status.phase
```

### Case A — database is already on `16.8-pgvector` (upgrading pgvector 0.8.1 → 0.8.4)

1. **Bump the catalog image.**

   > Skip creating the `PostgresVersion` if `16.8-pgvector` already exists — just
   > patch the existing one. Do **not** re-apply `example/catalog.yaml`, that would
   > revert the image.

   ```bash
   kubectl patch pgversion 16.8-pgvector --type=merge \
     -p '{"spec":{"db":{"image":"souravbiswassanto/postgres:16.8-pgvector-0.8.4"}}}'
   ```

   Note this changes the image for **every** database using `16.8-pgvector`. if you have other databases that use this version, contact us.

2. **Patch a label on the Postgres object** so the provisioner re-renders the PetSet:

   ```bash
   kubectl patch pg -n <> <> --type=merge \
     -p '{"metadata":{"labels":{"pgvector-version":"v0-8-4"}}}'

   kubectl get petset -n <> <> \
     -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
   ```

   Do not continue until the PetSet shows the `0.8.4` image.

3. **Restart:**

Restart the db pod. (only work for standalone)

4. **Run `ALTER EXTENSION` in every database that has `vector` installed.** The
   restart does not do this for you:

   ```bash
   # list the databases that have the extension
   kubectl exec -i -n <> <>-0 -c postgres -- psql -Atc \
     "SELECT datname FROM pg_database WHERE datallowconn AND NOT datistemplate;" \
     | while read db; do
         echo "== $db"
         kubectl exec -i -n <> <>-0 -c postgres -- psql -d "$db" -Atc \
           "SELECT extversion FROM pg_extension WHERE extname='vector';"
       done
   ```

   Then, for each database that returned a version:

   ```bash
   kubectl exec -i -n <> <>-0 -c postgres -- \
     psql -d <database-name> -c "ALTER EXTENSION vector UPDATE;"
   ```

5. **Verify** as in Step 1.8 — check `extversion` is `0.8.4` and that your existing
   vector tables, embeddings and HNSW/IVFFlat indexes are intact.


## Reference

| Item | Value |
|---|---|
| Extension name in SQL | `vector` (not `pgvector`) |
| Extension files | `/usr/local/share/postgresql/extension/vector.control` |
| Postgres version | `16.8` |
| Catalog `PostgresVersion` | `16.8-pgvector` |
