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

FROM postgres:11.2-alpine
# FROM kubedb/postgres:11.2

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

# RUN sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'pg_cron,\2'/;s/,'/'/" /scripts/primary/postgresql.conf \
#    && echo "cron.database_name = 'postgres'" >> /scripts/primary/postgresql.conf
