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

FROM postgres:13.2-alpine AS builder

RUN  apk add --update alpine-sdk git postgresql-dev

RUN git clone https://github.com/pgaudit/pgaudit.git \
  && ls -la \
  && cd /pgaudit \
  && git checkout REL_13_STABLE \
  && make install USE_PGXS=1 PG_CONFIG=/usr/local/bin/pg_config

FROM postgres:13.2-alpine
COPY --from=builder /usr/local/share/postgresql /usr/local/share/postgresql
COPY --from=builder /usr/local/lib/postgresql /usr/local/lib/postgresql
