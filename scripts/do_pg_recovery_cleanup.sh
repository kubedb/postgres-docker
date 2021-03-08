#!/bin/bash

set -eou pipefail

mkdir -p "$PGDATA"
rm -f "$PGDATA"/recovery.conf
rm -f "$PGDATA"/recovery.done
if [[ "$MAJOR_PG_VERSION" == "9" ]]; then
    export PGWAL="$PGDATA/pg_xlog"
else
    export PGWAL="$PGDATA/pg_wal"
fi
mkdir -p "$PGWAL"/archive_status/
rm -rf "$PGWAL"/archive_status/*
