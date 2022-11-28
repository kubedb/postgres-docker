# Using pg_cron

1. Install KubeDB operator.

2. Add pg_cron version to KubeDB catalog.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-14.6-alpine-cron/example/catalog.yaml
```

3. Deploy a demo PostgreSQL database.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-14.6-alpine-cron/example/demo.yaml
```
