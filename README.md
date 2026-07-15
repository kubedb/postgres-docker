# postgres-docker

Percona Server for PostgreSQL + [`pg_tde`](https://docs.percona.com/pg-tde/)
container image for KubeDB, published as
`ghcr.io/appscode-images/percona-distribution-postgresql:<version>`.

## Why this image

KubeDB's Transparent Data Encryption (TDE) support uses Percona's `pg_tde`
extension. Its `tde_heap` access method requires the **Percona Server for
PostgreSQL** fork, not community PostgreSQL, so TDE cannot run on the stock
`postgres:<major>-bookworm` image. This repository builds a Percona server image
that keeps the exact same runtime contract KubeDB already relies on, so the
existing init-container run scripts work against it unchanged:

- `postgres` user and group at **uid/gid 999** (matches
  `spec.securityContext.runAsUser: 999`)
- server binaries on `PATH` at `/usr/lib/postgresql/<major>/bin`
- the TDE tooling KubeDB needs: `pg_tde_basebackup` (encrypted replica seeding)
  and `pg_tde_rewind` (safe failback), verified present at build time
- the Docker official `docker-entrypoint.sh`, initdb helpers and `gosu`, borrowed
  verbatim from `postgres:<major>-bookworm` via a multi-stage copy
- identical `PGDATA`, locale, `VOLUME`, `STOPSIGNAL SIGINT` and `EXPOSE 5432`

At runtime KubeDB overrides the command with its own scripts and points `PGDATA`
at its mount, so the layout, user and binaries are what matter, and they all
match the official image.

## Catalog wiring

Reference it from the `PostgresVersion` catalog entry:

```yaml
spec:
  db:
    baseOS: bookworm
    image: ghcr.io/appscode-images/percona-distribution-postgresql:17.9
  distribution: Percona
  securityContext:
    runAsAnyNonRoot: true
    runAsUser: 999
  tde:
    supported: true
    extensionName: pg_tde
```

Note this differs from pointing at the upstream `percona/percona-distribution-postgresql`
image, which is UBI-based (uid 26, `/usr/pgsql-17/bin`, `PGDATA=/data/db`) and
does not match the KubeDB runtime.

## Build

```bash
# latest minor of the 17 line
make container TAG=17

# pin an exact Percona minor so the tag is truthful
#   find the version string with:  apt-cache madison percona-postgresql-17
make container PG_VERSION=2:17.9-1.bookworm TAG=17.9

# publish
make push TAG=17.9

# confirm the baked-in server version matches the tag
make version TAG=17.9
```

`make` variables: `REGISTRY` (default `ghcr.io/appscode-images`), `PG_MAJOR`
(default `17`), `TAG`, `PG_VERSION` (empty tracks latest minor).

## Notes

- Percona ships `pg_tde` as a hard dependency of the server package now, but the
  Dockerfile installs `percona-postgresql-<major>-pg-tde` explicitly for clarity.
- `shared_preload_libraries` is intentionally left empty in the image; KubeDB
  composes it (with `pg_tde` first) in its start scripts when TDE is enabled.
