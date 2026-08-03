# Stage 1: Builder
FROM postgres:16.4-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    postgresql16-dev \
    openssl-dev \
    clang \
    llvm-dev \
    krb5-dev \
    libxslt-dev \
    libxml2-dev \
    libedit-dev \
    autoconf \
    automake \
    && ln -sf /usr/bin/clang-16 /usr/bin/clang-15 \
    && mkdir -p /usr/lib/llvm15/bin \
    && for tool in /usr/lib/llvm16/bin/*; do ln -sf "$tool" /usr/lib/llvm15/bin/$(basename "$tool"); done

# Clone and build pgactive
WORKDIR /tmp/pgactive
RUN git clone --depth 1 --branch add_all_postgres_versions_support_for_pgactive https://github.com/aws/pgactive.git . \
    && ./configure \
    && make -j$(nproc) \
    && make install

# Stage 2: Runtime (slim)
FROM postgres:16.4-alpine

# Copy built extension
COPY --from=builder /usr/local/share/postgresql/extension/ /usr/local/share/postgresql/extension/
COPY --from=builder /usr/local/lib/postgresql/ /usr/local/lib/postgresql/

# Runtime deps if needed
RUN apk add --no-cache \
    postgresql16-contrib \
    ca-certificates \
    openssl

# Recommended configs (can be overridden via mounts)
# COPY <<EOF /docker-entrypoint-initdb.d/00-pgactive.conf
# # postgresql.conf overrides
# shared_preload_libraries = 'pgactive'
# wal_level = logical
# track_commit_timestamp = on
# max_replication_slots = 10          # Adjust for nodes + buffer
# max_wal_senders = 10
# max_logical_replication_workers = 10
# wal_sender_timeout = 30s
# wal_receiver_timeout = 30s
# EOF

# # Health check example
# HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
#     CMD pg_isready -U postgres