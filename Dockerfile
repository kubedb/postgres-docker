FROM postgres:16.8
ARG TT_VERSION=v1.2.2



RUN set -eux \
   && apt-get update \
   && apt-get install -y --no-install-recommends \
   ca-certificates \
   build-essential \
   git \
   postgresql-server-dev-16 \
   \
   && git clone --branch ${TT_VERSION} --depth 1 \
   https://github.com/arkhipov/temporal_tables /tmp/tt \
   && make  -C /tmp/tt \
   && make  -C /tmp/tt install \
   \
   # cleanup
   && rm -rf /tmp/tt /var/lib/apt/lists/*