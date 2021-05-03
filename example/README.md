# Using postgis

1. Install KubeDB operator.

2. Add postgis version to KubeDB catalog.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-10.16-postgis/example/catalog.yaml
```

3. Deploy a demo PostgreSQL database.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-10.16-postgis/example/demo.yaml
```
