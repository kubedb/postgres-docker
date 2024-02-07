# Using pg_cron

1. Install KubeDB operator.

2. Add pg_cron version to KubeDB catalog.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-11.16-alpine-cron/example/catalog.yaml
```

3. need to provide `shared_preload_libraries = 'pg_cron'` config inside `postgreSQL` `conf` file to enable pg-corn extension. At first, let’s create a secret with `user.conf` as key and  set `shared_preload_libraries` there.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-11.16-alpine-cron/example/custom-config.yaml
```

4. Deploy a demo PostgreSQL database.
```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-11.16-alpine-cron/example/demo.yaml
```

5. Then We need to create extension for our server. For This we need to exec into primary and create pgcron Extension

```shell
$ kubectl exec -it -n demo demo-pgcron-0  -- bash
$ psql
postgres=# CREATE EXTENSION pg_cron;
```