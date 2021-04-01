# Using pg_squeeze

1. Install KubeDB operator.

2. Add pg_squeeze version to KubeDB catalog.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-11.11-alpine-pgsqueeze/example/catalog.yaml
```

3. Deploy a demo PostgreSQL database.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-11.11-alpine-pgsqueeze/example/demo.yaml
```
