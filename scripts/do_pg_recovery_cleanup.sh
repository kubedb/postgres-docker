#!/usr/bin/env bash


set -eou pipefail

mkdir -p "$PGDATA"
rm -f "$PGDATA"/recovery.conf
rm -f "$PGDATA"/recovery.done

export PGWAL="$PGDATA/pg_wal"

mkdir -p "$PGWAL"/archive_status/
rm -rf "$PGWAL"/archive_status/*
