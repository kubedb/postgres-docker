# PostgreSQL with wal2json Extension

## Overview
These Docker images include the wal2json extension for PostgreSQL logical decoding, which allows you to consume database changes in JSON format.

## Images Available
- **Bookworm (Debian)**: `Dockerfile` - PostgreSQL 17 on Debian Bookworm
- **Alpine**: `Dockerfile.alpine` - PostgreSQL 17 on Alpine Linux (smaller image)

## Configuration Required

### 1. PostgreSQL Configuration
To use wal2json, you need to enable logical replication. Add these settings to your `postgresql.conf`:

```conf
# Required for logical replication
wal_level = logical

# Optional but recommended - adjust based on your needs
max_replication_slots = 10
max_wal_senders = 10
```

**Note**: Unlike some extensions, wal2json does **NOT** need to be added to `shared_preload_libraries`.

### 2. Create a Replication Slot

Connect to your database and create a replication slot:

```sql
-- Create a logical replication slot using wal2json
SELECT * FROM pg_create_logical_replication_slot('test_slot', 'wal2json');
```

### 3. Consume Changes

#### Using SQL API:
```sql
-- Get changes in JSON format (version 2)
SELECT * FROM pg_logical_slot_get_changes('test_slot', NULL, NULL, 'format-version', '2');

-- Get changes in JSON format (version 1)
SELECT * FROM pg_logical_slot_get_changes('test_slot', NULL, NULL, 'format-version', '1');

-- Peek at changes without consuming them
SELECT * FROM pg_logical_slot_peek_changes('test_slot', NULL, NULL, 'format-version', '2');
```

#### Using Streaming Replication Protocol:
You can also consume changes using the PostgreSQL replication protocol from client applications.

## Docker Usage Examples

### Docker Run
```bash
# Using Bookworm image
docker run -d \
  --name postgres-wal2json \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -e POSTGRES_DB=mydb \
  -p 5432:5432 \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:17-bookworm-wal2json \
  -c wal_level=logical \
  -c max_replication_slots=10 \
  -c max_wal_senders=10

# Using Alpine image (smaller)
docker run -d \
  --name postgres-wal2json \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -e POSTGRES_DB=mydb \
  -p 5432:5432 \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:17-alpine-wal2json \
  -c wal_level=logical \
  -c max_replication_slots=10 \
  -c max_wal_senders=10
```

### Docker Compose
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:17-bookworm-wal2json
    environment:
      POSTGRES_PASSWORD: mysecretpassword
      POSTGRES_DB: mydb
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    command:
      - "postgres"
      - "-c"
      - "wal_level=logical"
      - "-c"
      - "max_replication_slots=10"
      - "-c"
      - "max_wal_senders=10"
    
volumes:
  postgres-data:
```

### Kubernetes (KubeDB)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
data:
  postgresql.conf: |
    wal_level = logical
    max_replication_slots = 10
    max_wal_senders = 10
---
# Use the ConfigMap in your PostgreSQL deployment
```

## Testing the Extension

```sql
-- 1. Create a test table
CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 2. Create a replication slot
SELECT * FROM pg_create_logical_replication_slot('test_slot', 'wal2json');

-- 3. Insert some data
INSERT INTO test_table (name) VALUES ('Alice'), ('Bob'), ('Charlie');

-- 4. View the changes in JSON format
SELECT data FROM pg_logical_slot_get_changes('test_slot', NULL, NULL, 
    'format-version', '2',
    'include-timestamp', 'true'
);

-- 5. Clean up (when done)
SELECT pg_drop_replication_slot('test_slot');
```

## wal2json Options

### Format Version 1 (default)
Produces one JSON object per transaction with all changes included.

```sql
SELECT data FROM pg_logical_slot_get_changes('test_slot', NULL, NULL, 
    'format-version', '1',
    'include-timestamp', 'true',
    'include-schemas', 'true',
    'include-types', 'true'
);
```

### Format Version 2
Produces one JSON object per tuple (row change).

```sql
SELECT data FROM pg_logical_slot_get_changes('test_slot', NULL, NULL, 
    'format-version', '2',
    'include-timestamp', 'true',
    'include-transaction', 'true'
);
```

### Common Options
- `format-version`: '1' or '2'
- `include-timestamp`: Include transaction timestamp
- `include-schemas`: Include schema names
- `include-types`: Include column data types
- `include-transaction`: Include transaction markers (v2 only)
- `include-xids`: Include transaction IDs
- `filter-tables`: Filter specific tables (e.g., 'public.table1,public.table2')

## Build Instructions

```bash
# Build Bookworm image
docker build -t postgres:17-bookworm-wal2json -f Dockerfile .

# Build Alpine image
docker build -t postgres:17-alpine-wal2json -f Dockerfile.alpine .
```

## Important Notes

1. **wal_level=logical** is required - This is the most important setting
2. **NOT in shared_preload_libraries** - wal2json doesn't need to be preloaded
3. **Replication slots** - Remember to drop unused replication slots to prevent WAL buildup
4. **Permissions** - Users need REPLICATION privilege or be a superuser to create replication slots
5. **WAL retention** - Monitor disk space as replication slots prevent WAL cleanup until consumed

## References
- [wal2json GitHub](https://github.com/eulerto/wal2json)
- [PostgreSQL Logical Decoding](https://www.postgresql.org/docs/current/logicaldecoding.html)

