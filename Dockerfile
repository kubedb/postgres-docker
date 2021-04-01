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

FROM postgres:13.2 AS builder
RUN  apt-get update &&   apt-get install git -y &&  apt-get install build-essential -y && apt-get install postgresql-server-dev-13 -y
RUN export PG_CONFIG=$(which pg_config)
RUN git clone https://github.com/cybertec-postgresql/pg_squeeze.git
RUN cd /pg_squeeze && git checkout REL1_3_1
RUN cd /pg_squeeze && make
RUN mkdir -p  /var/lib/postgresql/data/postgres && chown postgres /var/lib/postgresql/data/postgres
RUN cd /pg_squeeze && make install

FROM postgres:13.2
COPY --from=builder /usr/share/postgresql /usr/share/postgresql
COPY --from=builder /usr/lib/postgresql /usr/lib/postgresql
USER postgres



