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

FROM postgres:15.5-alpine as builder
RUN  apk add --update alpine-sdk clang15-dev llvm15 perl postgresql15-dev bison libc-dev gcc git flex zlib-dev readline-dev build-base

RUN git clone https://github.com/apache/age.git \
  && cd /age \
  && git checkout release/PG15/1.5.0 \
  && make install PG_CONFIG=/usr/local/bin/pg_config

FROM postgres:15.5-alpine
COPY --from=builder /usr/local/share/postgresql /usr/local/share/postgresql
COPY --from=builder /usr/local/lib/postgresql /usr/local/lib/postgresql
