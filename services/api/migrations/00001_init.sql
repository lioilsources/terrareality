-- +goose Up
-- Extensions used across the platform. postgis: geo, vector: embeddings (pgvector),
-- pg_trgm + unaccent: Czech fulltext and fuzzy search, ltree: admin unit hierarchy,
-- citext: case-insensitive e-mails.
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- +goose StatementBegin
-- UUID v7 (RFC 9562): time-ordered, index-friendly primary keys.
CREATE OR REPLACE FUNCTION uuid_v7() RETURNS uuid
LANGUAGE plpgsql VOLATILE AS $$
DECLARE
  ts_ms bigint := floor(extract(epoch FROM clock_timestamp()) * 1000);
  b bytea := gen_random_bytes(16);
BEGIN
  b := set_byte(b, 0, ((ts_ms >> 40) & 255)::int);
  b := set_byte(b, 1, ((ts_ms >> 32) & 255)::int);
  b := set_byte(b, 2, ((ts_ms >> 24) & 255)::int);
  b := set_byte(b, 3, ((ts_ms >> 16) & 255)::int);
  b := set_byte(b, 4, ((ts_ms >> 8) & 255)::int);
  b := set_byte(b, 5, (ts_ms & 255)::int);
  b := set_byte(b, 6, (get_byte(b, 6) & 15) | 112);  -- version 7
  b := set_byte(b, 8, (get_byte(b, 8) & 63) | 128);  -- variant 10
  RETURN encode(b, 'hex')::uuid;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
-- Generic updated_at trigger, attached to mutable tables in later migrations.
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;
-- +goose StatementEnd

-- Key/value store for platform-level settings (e.g. seed markers).
CREATE TABLE app_meta (
  key        text PRIMARY KEY,
  value      jsonb NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER app_meta_updated_at BEFORE UPDATE ON app_meta
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE IF EXISTS app_meta;
DROP FUNCTION IF EXISTS set_updated_at();
DROP FUNCTION IF EXISTS uuid_v7();
