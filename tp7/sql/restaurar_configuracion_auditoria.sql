-- Opcional: revierte los parametros globales de auditoria de este laboratorio
-- a la configuracion por defecto del servidor local. Ejecutar como postgres.

ALTER SYSTEM RESET log_connections;
ALTER SYSTEM RESET log_disconnections;
ALTER SYSTEM RESET log_statement;
ALTER SYSTEM RESET log_line_prefix;
SELECT pg_reload_conf();
