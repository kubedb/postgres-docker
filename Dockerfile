# Build stage
FROM postgres:16.4-alpine as builder

# Set versions for pg_partman and pg_jobmon
ENV PG_REPACK_VERSION=1.5.2
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}"
# Install build dependencies
RUN apk add --no-cache --virtual .build-deps \
    ca-certificates \
    openssl \
    tar \
    unzip \
    curl \
    make \
    gcc \
    libc-dev \
    postgresql-dev \
    cmake \
    alpine-sdk \
    util-linux-dev \
    clang15-dev \
    llvm15 \
    gawk \
    git \
    zlib-dev \
    postgresql15-dev \
    alpine-sdk

Run curl -LO https://api.pgxn.org/dist/pg_repack/${PG_REPACK_VERSION}/pg_repack-${PG_REPACK_VERSION}.zip
RUN unzip pg_repack-${PG_REPACK_VERSION}.zip
RUN cd pg_repack-${PG_REPACK_VERSION} && make && make install

# Clean up build dependencies
RUN apk del .build-deps

# Final stage
FROM postgres:16.4-alpine

# Copy the built extensions from the builder stage
COPY --from=builder /usr/local/lib/postgresql/ /usr/local/lib/postgresql/
COPY --from=builder /usr/local/share/postgresql/ /usr/local/share/postgresql/
COPY --from=builder /usr/local/bin/pg_repack /usr/local/bin/


# Install runtime dependencies
RUN apk add --no-cache libpq libxml2-dev
