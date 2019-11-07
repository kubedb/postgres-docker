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

FROM debian:stretch as builder

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl unzip

RUN set -x                                                                                                                                              \
  && curl -fsSL -o pg-leader-election-binaries.zip https://github.com/kubedb/pg-leader-election/releases/download/v0.1.0/pg-leader-election-binaries.zip \
  && unzip pg-leader-election-binaries.zip                                                                                                              \
  && chmod 755 pg-leader-election-binaries/linux_amd64/pg-leader-election

RUN set -x                                                                                             \
  && curl -fsSL -o wal-g https://github.com/kubedb/wal-g/releases/download/0.2.13-ac/wal-g-alpine-amd64 \
  && chmod 755 wal-g

FROM postgres:9.6-alpine

RUN set -x \
  && apk add --update --no-cache ca-certificates

ENV PV /var/pv
ENV PGDATA $PV/data
ENV PGWAL $PGDATA/pg_xlog
ENV INITDB /var/initdb
ENV WALG_D /etc/wal-g.d/env

COPY --from=builder /pg-leader-election-binaries/linux_amd64/pg-leader-election /usr/bin/
COPY --from=builder /wal-g /usr/bin/

COPY scripts /scripts

VOLUME ["$PV"]

ENV STANDBY warm
ENV RESTORE false
ENV BACKUP_NAME LATEST
ENV PITR latest
ENV ARCHIVE_S3_PREFIX ""
ENV ARCHIVE_S3_ENDPOINT ""
ENV RESTORE_S3_PREFIX ""
ENV RESTORE_S3_ENDPOINT ""

ENV ARCHIVE_GS_PREFIX ""
ENV RESTORE_GS_PREFIX ""

ENV ARCHIVE_AZ_PREFIX ""
ENV RESTORE_AZ_PREFIX ""

ENV ARCHIVE_SWIFT_PREFIX ""
ENV RESTORE_SWIFT_PREFIX ""

ENV ARCHIVE_FILE_PREFIX ""
ENV RESTORE_FILE_PREFIX ""

ENTRYPOINT ["pg-leader-election"]

EXPOSE 5432
