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

FROM postgres:10.16 as builder
RUN apt-get update \
  && apt-get install -y git build-essential wget git postgresql-server-dev-10
RUN wget -q  http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2
RUN tar -xf scws-1.2.3.tar.bz2
RUN cd scws-1.2.3 && ./configure && make install
RUN  git clone https://github.com/amutu/zhparser.git
RUN cd zhparser &&  make && make install


FROM postgres:10.16
RUN  apt-get update \
  && apt-get install -y postgis postgresql-10-postgis-3
COPY --from=builder /usr/share/postgresql /usr/share/postgresql
COPY --from=builder /usr/lib/postgresql /usr/lib/postgresql
COPY --from=builder /usr/local/lib/libscws.so* /usr/local/lib/


