#!/bin/bash
set -eou pipefail

touch /tmp/recovery.conf
echo "standby_mode = on" >>/tmp/recovery.conf
echo "trigger_file = '/run_scripts/tmp/pg-failover-trigger'" >>/tmp/recovery.conf
echo "recovery_target_timeline = 'latest'" >>/tmp/recovery.conf

# primary_conninfo is used for streaming replication
if [[ "${SSL:-0}" == "ON" ]]; then
    if [[ "$CLIENT_AUTH_MODE" == "cert" ]]; then
        echo "primary_conninfo = 'application_name=$HOSTNAME host=$PRIMARY_HOST password=$POSTGRES_PASSWORD sslmode=$SSL_MODE sslrootcert=/tls/certs/client/ca.crt sslcert=/tls/certs/client/client.crt sslkey=/tls/certs/client/client.key'" >>/tmp/recovery.conf
    else
        echo "primary_conninfo = 'application_name=$HOSTNAME host=$PRIMARY_HOST password=$POSTGRES_PASSWORD sslmode=$SSL_MODE sslrootcert=/tls/certs/client/ca.crt'" >>/tmp/recovery.conf
    fi
else
    echo "primary_conninfo = 'application_name=$HOSTNAME host=$PRIMARY_HOST password=$POSTGRES_PASSWORD'" >>/tmp/recovery.conf
fi

mv /tmp/recovery.conf "$PGDATA/recovery.conf"
