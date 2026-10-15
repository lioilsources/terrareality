-- Runs once on an empty data directory (docker-entrypoint-initdb.d).
-- Temporal persistence lives on the same server in its own databases and role.
-- The password is set afterwards from TEMPORAL_DB_PASSWORD by init-roles.sh.
CREATE ROLE temporal LOGIN;
CREATE DATABASE temporal OWNER temporal;
CREATE DATABASE temporal_visibility OWNER temporal;
