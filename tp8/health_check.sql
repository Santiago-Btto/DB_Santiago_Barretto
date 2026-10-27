-- Ejecutar conectado a foodstore. Lecturas sin cambios de datos.
SELECT current_database() AS base, clock_timestamp() AS revisado_en,
       current_setting('server_version') AS version_postgresql,
       pg_size_pretty(pg_database_size(current_database())) AS tamano;

SELECT datname, numbackends AS conexiones_actuales, xact_commit,
       xact_rollback, deadlocks, stats_reset
FROM pg_stat_database
WHERE datname = current_database();

SELECT relname AS tabla, n_live_tup AS filas_estimadas,
       n_dead_tup AS tuplas_muertas_estimadas, n_mod_since_analyze,
       last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC, relname;

SELECT pid, usename, application_name, state,
       clock_timestamp() - query_start AS duracion,
       wait_event_type, wait_event,
       LEFT(query, 160) AS consulta_inicio
FROM pg_stat_activity
WHERE datname = current_database() AND state IS DISTINCT FROM 'idle'
ORDER BY query_start NULLS LAST;
