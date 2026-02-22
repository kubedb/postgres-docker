# FROM percona/percona-distribution-postgresql:17

# USER root
# RUN dnf -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
# RUN percona-release enable-only ppg-17
# RUN dnf install -y percona-pg_tde-17
    
# USER postgres

FROM percona/percona-distribution-postgresql:16

USER root

RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        build-essential \
        postgresql-server-dev-16 \
    \
    # Clone pg_tde
    && git clone --depth 1 https://github.com/percona/pg_tde.git /tmp/pg_tde \
    \
    # Build extension
    && make -C /tmp/pg_tde USE_PGXS=1 \
    && make -C /tmp/pg_tde USE_PGXS=1 install \
    \
    # Cleanup
    && rm -rf /tmp/pg_tde /var/lib/apt/lists/*

USER postgres
