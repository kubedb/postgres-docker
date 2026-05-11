# =============================================================================
# PostgreSQL 17 Bookworm — Custom Image
# Extensions: pgvector 0.8.2, PostGIS 3.6.2, pg_repack 1.5.3,
#              pg_cron 1.6.7, pgaudit 17.x
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Builder
# -----------------------------------------------------------------------------
FROM ghcr.io/appscode-images/postgres:17.9-bookworm AS builder

# Extension versions pinned to PostgreSQL 17 compatible releases
ENV PGVECTOR_VERSION=0.8.2
ENV POSTGIS_VERSION=3.6.2
ENV PG_REPACK_VERSION=1.5.3
ENV PG_CRON_VERSION=1.6.7
# pgaudit uses the REL_17_STABLE branch (tracks the latest 17.x patch)
ENV PGAUDIT_VERSION=REL_17_STABLE

# Ensure pg_config is on PATH
ENV PATH="/usr/lib/postgresql/17/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

# ---------------------------------------------------------------------------
# Install build-time dependencies
# ---------------------------------------------------------------------------
RUN apt-get update

RUN apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    ca-certificates \
    clang \
    cmake \
    curl \
    g++ \
    gawk \
    gcc \
    gettext \
    git \
    libc-dev \
    libcunit1-dev \
    libgdal-dev \
    libgeos-dev \
    libkrb5-dev \
    liblz4-dev \
    libjson-c-dev \
    libpcre2-dev \
    libpq-dev \
    libproj-dev \
    libprotobuf-c-dev \
    libreadline-dev \
    libsfcgal-dev \
    libxml2-dev \
    libtool \
    llvm-dev \
    make \
    pkg-config \
    postgresql-server-dev-17 \
    protobuf-c-compiler \
    unzip \
    zlib1g-dev

RUN rm -rf /var/lib/apt/lists/*

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


# =============================================================================
# Stage 2: Final image
# =============================================================================
FROM ghcr.io/appscode-images/postgres:17.9-bookworm

# Runtime libraries required by the extensions
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgdal32 \
        libgeos-c1v5 \
        libjson-c5 \
        libpcre2-8-0 \
        libproj25 \
        libprotobuf-c1 \
        libsfcgal1 \
        libxml2 \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled extension files from builder
COPY --from=builder /usr/lib/postgresql/17/lib/ /usr/lib/postgresql/17/lib/
COPY --from=builder /usr/share/postgresql/17/extension/ /usr/share/postgresql/17/extension/

# pg_repack ships a client binary as well
COPY --from=builder /usr/lib/postgresql/17/bin/pg_repack /usr/lib/postgresql/17/bin/pg_repack