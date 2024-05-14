## Copyright The KubeDB Authors.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
#
FROM postgres:15.5-bookworm AS builder

RUN apt-get update \
   && apt-get install -y git build-essential postgresql-server-dev-15 libreadline-dev zlib1g-dev flex bison clang-14
RUN git clone https://github.com/apache/age.git \
  && cd /age \
  && git checkout release/PG15/1.5.0 \
    && make PG_CONFIG=/usr/bin/pg_config install

FROM postgres:15.5-bookworm
COPY --from=builder /usr/share/postgresql /usr/share/postgresql
COPY --from=builder /usr/lib/postgresql /usr/lib/postgresql
