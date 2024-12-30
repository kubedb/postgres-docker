# Using pg-partman

1. Install KubeDB operator.

2. Add pg-partman version to KubeDB catalog.

```bash
kubectl apply -f https://raw.githubusercontent.com/kubedb/postgres-docker/refs/heads/release-16.4-alpine-pg-partman/example/catalog.yaml
```

3. Deploy a demo PostgreSQL database.

```
kubectl apply -f https://raw.githubusercontent.com/kubedb/postgres-docker/refs/heads/release-16.4-alpine-pg-partman/example/demo.yaml
```
