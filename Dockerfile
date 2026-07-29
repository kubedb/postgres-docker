# Percona Server for PostgreSQL + pg_tde, laid out to match the Docker official
# `postgres:<major>-bookworm` image so it is a drop-in for KubeDB.
#
# Why a dedicated image: pg_tde's `tde_heap` access method requires the Percona
# Server for PostgreSQL fork, not community PostgreSQL. This image installs the
# Percona distribution from Percona's apt repository while keeping the exact same
# runtime contract KubeDB already relies on for `postgres:<major>-bookworm`:
#   * a `postgres` user/group at uid/gid 999
#   * server binaries on PATH at /usr/lib/postgresql/<major>/bin
#   * the official docker-entrypoint.sh + gosu (borrowed from the upstream image)
#   * PGDATA, locale, VOLUME, STOPSIGNAL and EXPOSE identical to upstream
# KubeDB overrides the command with its init-container run scripts at runtime, so
# what matters is the layout, the user, and the binaries, all of which match.

ARG PG_MAJOR=17

# Borrow the proven entrypoint scripts and gosu from the Docker official image so
# we do not re-implement (and drift from) that contract.
FROM postgres:${PG_MAJOR}-bookworm AS upstream

FROM debian:bookworm-slim

ARG PG_MAJOR
ENV PG_MAJOR=${PG_MAJOR}
# Optionally pin the exact Percona minor (e.g. 2:17.9-1.bookworm) so the image
# tag can match the installed server version. Empty installs the latest 17.x.
# Find a value with: apt-cache madison percona-postgresql-17
ARG PG_VERSION=

LABEL org.opencontainers.image.source="https://github.com/kubedb/postgres-docker"
LABEL percona.package="Percona Server for PostgreSQL"

# Match the official image: create the postgres user *before* installing the
# server packages so the package postinst adopts uid/gid 999 instead of a
# distro-assigned id. KubeDB runs the pod as runAsUser 999.
RUN set -eux; \
	groupadd -r postgres --gid=999; \
	useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres; \
	mkdir -p /var/lib/postgresql; \
	chown -R postgres:postgres /var/lib/postgresql

# Base tooling + locale (en_US.UTF-8, same as upstream).
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		gnupg \
		lsb-release \
		locales \
		wget \
	; \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8; \
	rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.utf8

# Enable Percona's apt repo for the PostgreSQL 17 line, then install the Percona
# server, contrib (pg_stat_statements, etc.) and the pg_tde extension. pg_tde is
# a hard dependency of the server package now, but we name it explicitly so the
# intent (and the build) is unambiguous. `create_main_cluster = false` stops
# postgresql-common from spinning up a throwaway cluster during the build.
RUN set -eux; \
	apt-get update; \
	wget -qO /tmp/percona-release.deb "https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb"; \
	apt-get install -y --no-install-recommends /tmp/percona-release.deb; \
	rm -f /tmp/percona-release.deb; \
	percona-release setup ppg-17; \
	apt-get update; \
	mkdir -p /etc/postgresql-common; \
	echo 'create_main_cluster = false' > /etc/postgresql-common/createcluster.conf; \
	PIN=""; [ -n "${PG_VERSION}" ] && PIN="=${PG_VERSION}"; \
	apt-get install -y --no-install-recommends \
		percona-postgresql-${PG_MAJOR}${PIN} \
		percona-postgresql-client-${PG_MAJOR}${PIN} \
		percona-pg-tde${PG_MAJOR} \
		percona-postgresql-contrib \
	; \
	rm -rf /var/lib/apt/lists/*; \
	# sanity check: the Percona server and the pg_tde tooling KubeDB needs must be
	# present and on PATH. KubeDB uses pg_tde_basebackup for replica seeding,
	# pg_tde_rewind for failback, and pg_tde_waldump / pg_tde_resetwal in the
	# coordinator's failback WAL handling on an encrypted cluster (the plain tools
	# cannot read encrypted WAL). Missing any of these silently breaks TDE HA, so
	# assert them at build time.
	/usr/lib/postgresql/${PG_MAJOR}/bin/postgres --version; \
	for _bin in pg_tde_basebackup pg_tde_rewind pg_tde_waldump pg_tde_resetwal; do \
		test -x "/usr/lib/postgresql/${PG_MAJOR}/bin/${_bin}" \
			|| { echo "FATAL: required pg_tde tool ${_bin} not found in the image"; exit 1; }; \
	done

# Same PATH / PGDATA / run-dir setup as the official image. KubeDB overrides
# PGDATA to its own mount at runtime; this default keeps the image usable
# standalone.
ENV PATH=/usr/lib/postgresql/${PG_MAJOR}/bin:$PATH
ENV PGDATA=/var/lib/postgresql/data
RUN set -eux; \
	install --verbose --directory --owner postgres --group postgres --mode 1777 /var/run/postgresql; \
	install --verbose --directory --owner postgres --group postgres --mode 1777 "$PGDATA"

VOLUME /var/lib/postgresql/data

# Reuse the upstream entrypoint contract verbatim (entrypoint + initdb helpers +
# gosu) so behaviour is identical to postgres:<major>-bookworm.
COPY --from=upstream /usr/local/bin/gosu /usr/local/bin/gosu
COPY --from=upstream /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY --from=upstream /usr/local/bin/docker-ensure-initdb.sh /usr/local/bin/docker-ensure-initdb.sh
RUN set -eux; \
	ln -sfT docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh; \
	gosu --version; \
	gosu nobody true
ENTRYPOINT ["docker-entrypoint.sh"]

# postgres uses SIGINT for a fast shutdown; match upstream so orchestrators stop
# it cleanly.
STOPSIGNAL SIGINT
EXPOSE 5432

USER 999
CMD ["postgres"]
