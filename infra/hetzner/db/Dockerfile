# Production database image: the dev image (PostgreSQL 17 + PostGIS 3 + pgvector,
# infra/dev/postgres) plus pgBackRest from the PGDG repository.
# Build the base first:  docker build -t terra/postgres:17-postgis-pgvector infra/dev/postgres
# Used by infra/hetzner/compose/docker-compose.db.yml and scripts/restore-test.sh.
ARG BASE_IMAGE=terra/postgres:17-postgis-pgvector
FROM ${BASE_IMAGE}
RUN apt-get update \
 && apt-get install -y --no-install-recommends pgbackrest ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /var/log/pgbackrest /var/lib/pgbackrest /var/spool/pgbackrest /etc/pgbackrest/conf.d \
 && chown -R postgres:postgres /var/log/pgbackrest /var/lib/pgbackrest /var/spool/pgbackrest \
 && chmod 750 /var/log/pgbackrest /var/lib/pgbackrest /var/spool/pgbackrest
COPY pgbackrest.conf /etc/pgbackrest/pgbackrest.conf
COPY postgresql.conf /etc/postgresql/postgresql.conf
# Init hooks: Temporal databases + role, pgBackRest stanza (only on an empty data dir).
COPY --chmod=0755 initdb/ /docker-entrypoint-initdb.d/
# Run with: postgres -c config_file=/etc/postgresql/postgresql.conf
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
