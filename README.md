### Build You Own Image using docker build

docker build -t <change-it>/postgres:16.8-pgvector  .

### Push Your Image

docker push <change-it>/postgres:16.8-pgvector

### Create a pgvector postgresversion yaml

edit the example/catalog.yaml and change `.spec.db.image` part with your

`<change-it>/postgres:16.8-pgvector`


### Apply the new pgvector postgresversion object

`kubectl apply -f example/catalog.yal`

### Verify if new pgversion is available in the cluster

`kubectl get pgversion 16.8-pgvector -oyaml`

### Update Existing Postgres Database

This is the case when you have an existing postgres database with 16.8 already running.

To update that, we suggest you first test below process on your environment.


1. Create a postgres database using version `16.8`, wait for it become ready.

2. Edit the postgres object and update version to `16.8-pgvector` from `16.8`. `kubectl get pg -n <ns> <name>` should reflect your version change.

3. restart the standby databases first, once they come online, restart the primary.
4. The database should be ready again.
5. If everything works fine, you can update your client database following step 2 & 3.


### Create New Postgres Database

Creating new database is relatively simple, just create catalog.yaml with your image in it.

THen apply your database using the above version.



