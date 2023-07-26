#!/bin/bash

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# Create the 'template_tds_fdw' template db
"${psql[@]}" <<-'EOSQL'
CREATE DATABASE template_tds_fdw IS_TEMPLATE true;
EOSQL

# Load TDS FDW into both template_database and $POSTGRES_DB
for DB in template_tds_fdw "$POSTGRES_DB"; do
    echo "Loading TDS FDW extensions into $DB"
    "${psql[@]}" --dbname="$DB" <<-'EOSQL'
		CREATE EXTENSION IF NOT EXISTS tds_fdw;
EOSQL
done
