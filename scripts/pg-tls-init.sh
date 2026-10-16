#!/usr/bin/env bash
# Creates the internal CA and the PostgreSQL server certificate for the DB VM (review S-I12).
# Runs once on the DB VM as a sudoer; idempotent (keeps an existing CA, re-issues the server
# certificate with --renew). Output in PG_TLS_DIR (default /srv/pgtls):
#   ca.crt        internal CA: copy to the app VM as PG_CA_FILE (/etc/terrareality/secrets/pg-ca.crt)
#   server.crt    server certificate, SAN = DB_HOST (private IP) and the name "terra-db"
#   server.key    owned by the postgres uid (999), mode 0600
#   ssl.conf      included by infra/hetzner/db/postgresql.conf (include_if_exists); also points
#                 hba_file at pg_hba.conf below
#   pg_hba.conf   TLS-only client authentication: every TCP connection from outside the VM must be
#                 `hostssl` (plain TCP is rejected); the unix socket, loopback and the monitoring
#                 role from the Docker bridge on the same VM stay as before
# Then `db up -d db` (restart) and on the app VM `app up -d` (DATABASE_URL uses sslmode=verify-full,
# Temporal SQL_TLS_ENABLED with the same CA; DB_SSLMODE=verify-full and DB_TLS=true in the app .env).
# The CA key lives in PG_TLS_CA_DIR (default /srv/pgtls-ca, root only, never mounted into a
# container); move it OFF the VM into the password manager after issuing.
# Server certificate validity: 825 days; renew with --renew before expiry (docs/runbooks/key-rotation.md).
set -euo pipefail

DIR="${PG_TLS_DIR:-/srv/pgtls}"
CA_DIR="${PG_TLS_CA_DIR:-/srv/pgtls-ca}"
HOST_IP="${DB_HOST:-10.10.1.20}"
PG_UID="${PG_UID:-999}"
renew=0
[ "${1:-}" = "--renew" ] && renew=1

sudo install -d -m 0755 "$DIR"
sudo install -d -m 0700 -o root -g root "$CA_DIR"
cd "$DIR"

if [ ! -f ca.crt ]; then
  sudo test -f "$CA_DIR/ca.key" || sudo openssl genrsa -out "$CA_DIR/ca.key" 4096
  sudo openssl req -x509 -new -key "$CA_DIR/ca.key" -sha256 -days 3650 -subj "/CN=TerraReality internal DB CA" -out ca.crt
fi

if [ ! -f server.crt ] || [ "$renew" = 1 ]; then
  sudo test -f "$CA_DIR/ca.key" || { echo "$CA_DIR/ca.key missing: copy it back from the password manager to renew" >&2; exit 1; }
  sudo openssl genrsa -out server.key 2048
  sudo openssl req -new -key server.key -subj "/CN=terra-db" -out server.csr
  printf 'subjectAltName=IP:%s,DNS:terra-db,DNS:db\nextendedKeyUsage=serverAuth\n' "$HOST_IP" | sudo tee server.ext >/dev/null
  sudo openssl x509 -req -in server.csr -CA ca.crt -CAkey "$CA_DIR/ca.key" -CAserial "$CA_DIR/ca.srl" -CAcreateserial \
    -days 825 -sha256 -extfile server.ext -out server.crt
  sudo rm -f server.csr server.ext
fi

sudo tee ssl.conf >/dev/null <<'CONF'
ssl = on
ssl_cert_file = '/etc/postgresql/tls/server.crt'
ssl_key_file = '/etc/postgresql/tls/server.key'
ssl_ca_file = '/etc/postgresql/tls/ca.crt'
ssl_min_protocol_version = 'TLSv1.3'
# TLS-only pg_hba (written next to this file). Without ssl.conf (restore drills, a fresh VM) the
# image default $PGDATA/pg_hba.conf applies.
hba_file = '/etc/postgresql/tls/pg_hba.conf'
CONF

sudo tee pg_hba.conf >/dev/null <<'HBA'
# Written by scripts/pg-tls-init.sh (review S-I12). First match wins.
# TYPE     DATABASE     USER        ADDRESS          METHOD
# Inside the container: initdb hooks, pgBackRest, `docker exec psql`, pg_isready.
local      all          all                          trust
host       all          all         127.0.0.1/32     trust
host       all          all         ::1/128          trust
local      replication  all                          trust
host       replication  all         127.0.0.1/32     trust
host       replication  all         ::1/128          trust
# postgres-exporter on the same VM (Docker bridge, traffic never leaves the host).
host       terra        monitoring  172.16.0.0/12    scram-sha-256
# Everything else (api, worker, migrate, Temporal from the app VM over the private network): TLS only.
hostssl    all          all         0.0.0.0/0        scram-sha-256
hostssl    all          all         ::/0             scram-sha-256
hostnossl  all          all         all              reject
HBA

sudo chown "$PG_UID:$PG_UID" server.key server.crt ca.crt ssl.conf pg_hba.conf
sudo chmod 0600 server.key
sudo chmod 0644 server.crt ca.crt ssl.conf pg_hba.conf
echo "ok: $DIR (server certificate for $HOST_IP). Copy ca.crt to the app VM, then move $CA_DIR/ca.key off this VM."
