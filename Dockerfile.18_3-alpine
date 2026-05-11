# =============================================================================
# PostgreSQL 18 Alpine — Custom Image
# Extensions: pgvector 0.8.2, PostGIS 3.6.2, pg_repack 1.5.3,
#              pg_cron 1.6.7, pgaudit 18.x
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Builder
# -----------------------------------------------------------------------------
FROM ghcr.io/appscode-images/postgres:18.3-alpine AS builder

# Extension versions pinned to PostgreSQL 18 compatible releases
ENV PGVECTOR_VERSION=0.8.2
ENV POSTGIS_VERSION=3.6.2
ENV PG_REPACK_VERSION=1.5.3
ENV PG_CRON_VERSION=1.6.7
# pgaudit uses the REL_18_STABLE branch (tracks the latest 18.x patch)
ENV PGAUDIT_VERSION=REL_18_STABLE

# Ensure pg_config is on PATH
ENV PATH="/usr/local/pgsql/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

# ---------------------------------------------------------------------------
# Install build-time dependencies
# $DOCKER_PG_LLVM_DEPS is set by the base postgres Alpine image and resolves
# to the correct llvm/clang version for this PostgreSQL build.
# ---------------------------------------------------------------------------
RUN apk add --no-cache --virtual .build-deps \
    autoconf \
    automake \
    ca-certificates \
    clang \
    cmake \
    cunit-dev \
    curl \
    file \
    g++ \
    gawk \
    gcc \
    gdal-dev \
    geos-dev \
    gettext-dev \
    git \
    json-c-dev \
    krb5-dev \
    libtool \
    libxml2-dev \
    llvm \
    lz4-dev \
    make \
    openssl \
    pcre2-dev \
    perl \
    proj-dev \
    proj-util \
    protobuf-c-dev \
    sfcgal-dev \
    tar \
    unzip \
    util-linux-dev \
    zlib-dev \
    $DOCKER_PG_LLVM_DEPS

# ---------------------------------------------------------------------------
# 1. Build pgvector
# ---------------------------------------------------------------------------
RUN git clone --branch v${PGVECTOR_VERSION} --depth 1 \
        https://github.com/pgvector/pgvector.git /tmp/pgvector

RUN cd /tmp/pgvector \
    && make clean

RUN cd /tmp/pgvector \
    && make

RUN cd /tmp/pgvector \
    && make install

# ---------------------------------------------------------------------------
# 2. Build PostGIS
# ---------------------------------------------------------------------------
RUN curl -sSL \
        https://github.com/postgis/postgis/archive/${POSTGIS_VERSION}.tar.gz \
        -o /tmp/postgis.tar.gz

RUN mkdir -p /tmp/postgis \
    && tar --extract --file /tmp/postgis.tar.gz \
       --directory /tmp/postgis --strip-components 1 \
    && rm /tmp/postgis.tar.gz

RUN cd /tmp/postgis \
    && gettextize

RUN cd /tmp/postgis \
    && ./autogen.sh

RUN cd /tmp/postgis \
    && ./configure --enable-lto

RUN cd /tmp/postgis \
    && make -j$(nproc)

RUN cd /tmp/postgis \
    && make install

# ---------------------------------------------------------------------------
# 3. Build pg_repack
# ---------------------------------------------------------------------------
RUN curl -sSL \
        https://api.pgxn.org/dist/pg_repack/${PG_REPACK_VERSION}/pg_repack-${PG_REPACK_VERSION}.zip \
        -o /tmp/pg_repack.zip

RUN unzip /tmp/pg_repack.zip -d /tmp \
    && rm /tmp/pg_repack.zip

RUN cd /tmp/pg_repack-${PG_REPACK_VERSION} \
    && make

RUN cd /tmp/pg_repack-${PG_REPACK_VERSION} \
    && make install

# ---------------------------------------------------------------------------
# 4. Build pg_cron
# ---------------------------------------------------------------------------
RUN git clone --branch v${PG_CRON_VERSION} --depth 1 \
        https://github.com/citusdata/pg_cron.git /tmp/pg_cron

RUN cd /tmp/pg_cron \
    && make

RUN cd /tmp/pg_cron \
    && make install

# ---------------------------------------------------------------------------
# 5. Build pgaudit
# ---------------------------------------------------------------------------
RUN git clone --branch ${PGAUDIT_VERSION} --depth 1 \
        https://github.com/pgaudit/pgaudit.git /tmp/pgaudit

RUN cd /tmp/pgaudit \
    && make USE_PGXS=1

RUN cd /tmp/pgaudit \
    && make USE_PGXS=1 install

# ---------------------------------------------------------------------------
# Clean up build deps from builder layer (keep image lean for COPY)
# ---------------------------------------------------------------------------
RUN apk del .build-deps


# =============================================================================
# Stage 2: Final image
# =============================================================================
FROM ghcr.io/appscode-images/postgres:18.3-alpine

# Runtime libraries required by the extensions
RUN apk add --no-cache \
    gdal \
    geos \
    json-c \
    libpq \
    libstdc++ \
    libxml2 \
    pcre2 \
    proj \
    protobuf-c \
    sfcgal

# Copy compiled extension files from builder
COPY --from=builder /usr/local/lib/postgresql/ /usr/local/lib/postgresql/
COPY --from=builder /usr/local/share/postgresql/ /usr/local/share/postgresql/

# pg_repack ships a client binary as well
COPY --from=builder /usr/local/bin/pg_repack /usr/local/bin/pg_repack