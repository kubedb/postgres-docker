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

FROM postgres:15.3-alpine

ENV TDS_FDW_VERSION 2.0.3

RUN set -eux \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
    \
    && wget -O tds_fdw.tar.gz "https://github.com/tds-fdw/tds_fdw/archive/v${TDS_FDW_VERSION}.tar.gz" \
    && mkdir -p /usr/src/tds_fdw \
    && tar \
        --extract \
        --file tds_fdw.tar.gz \
        --directory /usr/src/tds_fdw \
        --strip-components 1 \
    && rm tds_fdw.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        \
        freetds-dev \
        gcc \
        libc-dev \
        make \
        postgresql-dev \
        \
        # The upstream variable, '$DOCKER_PG_LLVM_DEPS' contains
        #  the correct versions of 'llvm-dev' and 'clang' for the current version of PostgreSQL.
        # This improvement has been discussed in https://github.com/docker-library/postgres/pull/1077
        $DOCKER_PG_LLVM_DEPS \
        \
    \
# build TDS FDW
    && cd /usr/src/tds_fdw \
    && make USE_PGXS=1 \
    && make USE_PGXS=1 install \
    \
# add .postgis-rundeps
    && apk add --no-cache --virtual .postgis-rundeps \
        \
        freetds-dev \
    \
# clean
    && cd / \
    && rm -rf /usr/src/tds_fdw \
    && apk del .fetch-deps .build-deps

COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
