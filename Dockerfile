# syntax=docker/dockerfile:1

FROM postgres:16.8 AS production

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV PG_MAJOR_VERSION=16

RUN --mount=type=cache,sharing=locked,target=/var/cache/apt <<EOF
set -ex

apt update
apt upgrade -y
apt install -y \
    build-essential \
    cmake \
    curl \
    git \
    libicu-dev \
    libkrb5-dev \
    pkg-config \
    postgresql-16-cron \
    postgresql-16-pgvector \
    postgresql-16-postgis-3 \
    postgresql-16-rum \
    postgresql-server-dev-16
EOF

RUN --mount=target=/src,rw <<EOF
set -ex

cd /src

mkdir -p /tmp/install_setup
cp documentdb/scripts/* /tmp/install_setup/
cp 10-preload.sh 20-install.sql /docker-entrypoint-initdb.d/

export CLEANUP_SETUP=1
export INSTALL_DEPENDENCIES_ROOT=/tmp/install_setup

env MAKE_PROGRAM=cmake /tmp/install_setup/install_setup_libbson.sh
/tmp/install_setup/install_setup_pcre2.sh
/tmp/install_setup/install_setup_intel_decimal_math_lib.sh

cd documentdb
make -k -j $(nproc)
make install

rm -fr /tmp/install_setup /var/lib/apt/lists/*
EOF
RUN mkdir -p /tmp/postgresql/share && mkdir -p /tmp/postgresql/lib
RUN cp -Lr /usr/share/postgresql /tmp/postgresql/share
RUN cp -Lr /usr/lib/postgresql /tmp/postgresql/lib
# RUN cp -rL /usr/lib/x86_64-linux-gnu/ /tmp/postgresql/lib/postgresql/16/lib
# RUN cp -rL /usr/lib/x86_64-linux-gnu/libgeos* /usr/lib/x86_64-linux-gnu/libproj* /usr/lib/x86_64-linux-gnu/libgdal* /usr/lib/x86_64-linux-gnu/libjson-c* /usr/lib/x86_64-linux-gnu/libprotobuf-c* /tmp/postgresql/lib/postgresql/16/lib

# CMD ["sleep", "infinity"]

FROM postgres:16.8

# Copy the built extensions from the builder stage
COPY --from=production /tmp/postgresql/lib/postgresql /usr/lib/postgresql
COPY --from=production /tmp/postgresql/share/postgresql /usr/share/postgresql
COPY --from=production /usr/lib/x86_64-linux-gnu/ /usr/lib/x86_64-linux-gnu/