# -------- STAGE 1: Build pgvector --------
FROM postgres:13.13-alpine

ARG VECTOR_VERSION=v0.8.1

# Install build dependencies, build pgvector, then clean up
RUN apk add --no-cache --virtual .build-deps \
        git \
        build-base \
        clang15 \
        llvm15 \
    && git clone --branch ${VECTOR_VERSION} --depth 1 \
        https://github.com/pgvector/pgvector.git /tmp/pgvector \
    && cd /tmp/pgvector \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pgvector \
    && apk del .build-deps

# Optional: verify installation
RUN ls -l /usr/local/lib/postgresql/ | grep vector || true