# PostgreSQL 17 + PostGIS 3 + pgvector, multi-arch (arm64 Mac, amd64 servers).
# The official postgis/postgis image has no arm64 build, so we install both
# extensions from the PGDG apt repository bundled in the official image.
FROM postgres:18-bookworm
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      postgresql-17-postgis-3 postgresql-17-postgis-3-scripts postgresql-17-pgvector \
 && rm -rf /var/lib/apt/lists/*
