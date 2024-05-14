# Using tds_fdw

1. Install KubeDB operator.

2. Create catalog.yaml

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-15.3-alpine-tds_fdw/example/catalog.yaml
```

3. Deploy a demo PostgreSQL database.

```
kubectl apply -f https://github.com/kubedb/postgres-docker/raw/release-15.3-alpine-tds_fdw/example/demo.yaml
```
4. Wait until postgres is ready.
```bash
NAME                              VERSION         STATUS   AGE
postgres.kubedb.com/ha-postgres   15.5-bookworm   Ready    22m

```
5. Exec into the pod and run psql command.
```bash
kubectl exec -it -n demo ha-postgres-0 -- bash
Defaulted container "postgres" out of: postgres, pg-coordinator, postgres-init-container (init)
postgres@ha-postgres-0:/$ psql
psql (15.7 (Debian 15.7-1.pgdg120+1))
Type "help" for help.

postgres=# 

 ```
6. Run the queries to verify:
```sql
CREATE EXTENSION age;
LOAD 'age';
SET search_path = ag_catalog, postgres, public;


-- To create a graph, use the create_graph function located in the ag_catalog namespace.

SELECT create_graph('graph_name');
-- To create a single vertex, use the CREATE clause.

SELECT * 
FROM cypher('graph_name', $$
    CREATE (n)
$$) as (v agtype);
-- To create a single vertex with the label, use the CREATE clause.

SELECT * 
FROM cypher('graph_name', $$
    CREATE (:label)
$$) as (v agtype);
-- To query the graph, you can use the MATCH clause.

SELECT * 
FROM cypher('graph_name', $$
    MATCH (v)
    RETURN v
$$) as (v agtype);
-- You can use the following to create an edge, for example, between two nodes.

SELECT * 
FROM cypher('graph_name', $$
    MATCH (a:label), (b:label)
    WHERE a.property = 'Node A' AND b.property = 'Node B'
    CREATE (a)-[e:RELTYPE]->(b)
    RETURN e
$$) as (e agtype);
-- To create an edge and set properties.

SELECT * 
FROM cypher('graph_name', $$
    MATCH (a:label), (b:label)
    WHERE a.property = 'Node A' AND b.property = 'Node B'
    CREATE (a)-[e:RELTYPE {property:a.property + '<->' + b.property}]->(b)
    RETURN e
$$) as (e agtype);
-- Example

SELECT *
FROM cypher('graph_name', $$
    MATCH (a:Person), (b:Person)
                WHERE a.name = 'Node A' AND b.name = 'Node B'
                CREATE (a)-[e:RELTYPE {name:a.name + '<->' + b.name}]->(b)
    RETURN e
$$) as (e agtype);
            
```
