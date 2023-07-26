# Using tds_fdw

1. Install KubeDB operator.

2. Add tds_fdw version to KubeDB catalog.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-15.3-alpine-tds_fdw/example/catalog.yaml
```

3. Deploy a demo PostgreSQL database.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-15.3-alpine-tds_fdw/example/demo.yaml
```
