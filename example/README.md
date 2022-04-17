# Using pg-audit

1. Install KubeDB operator.

2. Add pg-audit version to KubeDB catalog.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-13.2-alpine-pgaudit/example/catalog.yaml
```
3. need to provide `shared_preload_libraries = 'pgaudit'` config inside `postgreSQL` `conf` file to enable pg-audit extension. At first, let’s create `user.conf` file setting `shared_preload_libraries`.
```shell
> cat user.conf
shared_preload_libraries = 'pgaudit'
```
4. Now, create a Secret with this configuration file.
```shell
kubectl create secret generic -n demo pg-configuration --from-file=user.conf=user.conf
```

5. Deploy a demo PostgreSQL database with this custom config.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-13.2-alpine-pgaudit/example/demo.yaml
```

6. Then We need to create extension for our server. For This we need to exec into primary and create pgAudit Extension

```shell
$ kubectl exec -it -n demo demo-pgaudit-0  -- bash
$ psql
postgres=# CREATE EXTENSION pgaudit;
```