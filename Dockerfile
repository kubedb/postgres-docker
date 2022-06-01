# FROM kubedb/postgres:11.2
FROM kubedb/postgres:11.16

ENV PG_CRON_VERSION=1.2.0
ENV PGCTLTIMEOUT=3600

RUN  apk add --update alpine-sdk git postgresql-dev

RUN set -ex \
    && apk add --no-cache --virtual .fetch-deps ca-certificates  openssl  tar \
    && apk add --no-cache --virtual .build-deps coreutils dpkg-dev dpkg gcc libc-dev make cmake util-linux-dev \
    && wget -O /pg_cron.tgz https://github.com/citusdata/pg_cron/archive/v$PG_CRON_VERSION.tar.gz \
    && tar xvzf /pg_cron.tgz \
    && cd pg_cron-$PG_CRON_VERSION \
    && sed -i.bak -e 's/-Werror//g' Makefile \
    && sed -i.bak -e 's/-Wno-implicit-fallthrough//g' Makefile \
    && make \
    && make install \
    && cd .. \
    && rm -rf pg_cron.tgz \
    && rm -rf pg_cron-* \
    && apk del .fetch-deps .build-deps

# https://github.com/citusdata/pg_cron#setting-up-pg_cron

RUN sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'pg_cron,\2'/;s/,'/'/" /scripts/primary/postgresql.conf \
   && echo "cron.database_name = 'postgres'" >> /scripts/primary/postgresql.conf
