FROM ghcr.io/appscode-images/postgres:18.3-bookworm

RUN apt update && apt install -y wget && wget https://github.com/pgxman/pgxman/releases/download/v1.4.2/pgxman_linux_amd64.deb && dpkg -i pgxman_linux_amd64.deb
RUN pgxman install -y --overwrite pgvector pg_cron pg_stat_statements pg_repack pg_audit
# Bookworm defaults postgres user to 999. Our existing Postgres uses id 70
# This changes the id of the user and group to match, and resets the group
# on the filesystem as well.
#RUN usermod -u 70 postgres \
#  && groupmod -g 70 postgres \
#  && find / -group 999 | xargs chgrp 70