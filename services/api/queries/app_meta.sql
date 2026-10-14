-- name: GetAppMeta :one
SELECT key, value, updated_at FROM app_meta WHERE key = $1;

-- name: UpsertAppMeta :exec
INSERT INTO app_meta (key, value) VALUES ($1, $2)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- name: NewUUIDv7 :one
SELECT uuid_v7()::uuid AS id;
