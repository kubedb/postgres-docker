#!/bin/bash

# Copyright The KubeDB Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

mkdir -p "$PGDATA"
rm -rf "$PGDATA"/*
chmod 0700 "$PGDATA"

export POSTGRES_INITDB_ARGS=${POSTGRES_INITDB_ARGS:-}
export POSTGRES_INITDB_WALDIR=${POSTGRES_INITDB_WALDIR:-}

# Create the transaction log directory before initdb is run
if [ "$POSTGRES_INITDB_WALDIR" ]; then
  mkdir -p "$POSTGRES_INITDB_WALDIR"
  chown -R postgres "$POSTGRES_INITDB_WALDIR"
  chmod 700 "$POSTGRES_INITDB_WALDIR"

  export POSTGRES_INITDB_ARGS="$POSTGRES_INITDB_ARGS --waldir $POSTGRES_INITDB_WALDIR"
fi

initdb $POSTGRES_INITDB_ARGS --pgdata="$PGDATA"

# setup postgresql.conf
touch /tmp/postgresql.conf
echo "wal_level = replica" >>/tmp/postgresql.conf
echo "max_wal_senders = 90" >>/tmp/postgresql.conf # default is 10.  value must be less than max_connections minus superuser_reserved_connections. ref: https://www.postgresql.org/docs/11/runtime-config-replication.html#GUC-MAX-WAL-SENDERS
echo "wal_keep_segments = 32" >>/tmp/postgresql.conf

cat /scripts/primary/postgresql.conf >>/tmp/postgresql.conf
mv /tmp/postgresql.conf "$PGDATA/postgresql.conf"

# setup pg_hba.conf
{
  echo
  echo 'local all         all                         trust'
} >>"$PGDATA/pg_hba.conf"
{ echo 'host  all         all         127.0.0.1/32    trust'; } >>"$PGDATA/pg_hba.conf"
{ echo 'host  all         all         0.0.0.0/0       md5'; } >>"$PGDATA/pg_hba.conf"
{ echo "host  replication ${POSTGRES_USER:-postgres}    0.0.0.0/0       md5"; } >>"$PGDATA/pg_hba.conf"

# start postgres
pg_ctl -D "$PGDATA" -w start

export POSTGRES_USER=${POSTGRES_USER:-postgres}
export POSTGRES_DB=${POSTGRES_DB:-$POSTGRES_USER}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}

psql=(psql -v ON_ERROR_STOP=1)

# create database with specified name
if [ "$POSTGRES_DB" != "postgres" ]; then
  "${psql[@]}" --username postgres <<-EOSQL
CREATE DATABASE "$POSTGRES_DB" ;
EOSQL
  echo
fi

if [ "$POSTGRES_USER" = "postgres" ]; then
  op="ALTER"
else
  op="CREATE"
fi

# alter postgres superuser
"${psql[@]}" --username postgres <<-EOSQL
    $op USER "$POSTGRES_USER" WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';
EOSQL
echo

psql+=(--username "$POSTGRES_USER" --dbname "$POSTGRES_DB")
echo

# initialize database
for f in "$INITDB"/*; do
  case "$f" in
    *.sh)
      echo "$0: running $f"
      . "$f"
      ;;
    *.sql)
      echo "$0: running $f"
      "${psql[@]}" -f "$f"
      echo
      ;;
    *.sql.gz)
      echo "$0: running $f"
      gunzip -c "$f" | "${psql[@]}"
      echo
      ;;
    *) echo "$0: ignoring $f" ;;
  esac
  echo
done

# stop server
pg_ctl -D "$PGDATA" -m fast -w stop

touch /tmp/postgresql.conf
if [ "$STREAMING" == "synchronous" ]; then
  # setup synchronous streaming replication
  echo "synchronous_commit = remote_write" >>/tmp/postgresql.conf
  echo "synchronous_standby_names = '*'" >>/tmp/postgresql.conf
fi

if [ "$ARCHIVE" == "wal-g" ]; then
  # setup postgresql.conf
  echo "archive_command = 'wal-g wal-push %p'" >>/tmp/postgresql.conf
  echo "archive_timeout = 60" >>/tmp/postgresql.conf
  echo "archive_mode = always" >>/tmp/postgresql.conf
fi

# ref: https://superuser.com/a/246841/985093
cat /tmp/postgresql.conf $PGDATA/postgresql.conf >"/tmp/postgresql.conf.tmp" && mv "/tmp/postgresql.conf.tmp" "$PGDATA/postgresql.conf"
