# Build stage
FROM postgres:16.4-alpine as builder

# Set versions for pg_partman and pg_jobmon
ENV PG_PARTMAN_VERSION=5.0.1
ENV PG_JOBMON_VERSION=1.4.1

# Install build dependencies
RUN apk add --no-cache --virtual .build-deps \
    ca-certificates \
    openssl \
    tar \
    make \
    gcc \
    libc-dev \
    postgresql-dev \
    llvm15 \
    clang15-dev \
    cmake \
    util-linux-dev \
    alpine-sdk \
    git \
    postgresql15-dev
# Download pg_partman source code
RUN git clone --branch v${PG_PARTMAN_VERSION} --depth 1 https://github.com/pgpartman/pg_partman.git /usr/src/pg_partman

# Download pg_jobmon source code
RUN git clone --branch v${PG_JOBMON_VERSION} --depth 1 https://github.com/omniti-labs/pg_jobmon.git /usr/src/pg_jobmon


# Build and install pg_partman
RUN cd /usr/src/pg_partman && make && make install

# Build and install pg_jobmon
RUN cd /usr/src/pg_jobmon && make && make install

# Clean up build dependencies
RUN apk del .build-deps

# Final stage
FROM postgres:16.4-alpine

# Copy the built extensions from the builder stage
COPY --from=builder /usr/local/lib/postgresql/ /usr/local/lib/postgresql/
COPY --from=builder /usr/local/share/postgresql/ /usr/local/share/postgresql/

# Install runtime dependencies
RUN apk add --no-cache libpq libxml2-dev

