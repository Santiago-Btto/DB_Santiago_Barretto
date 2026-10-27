-- Ejecutar conectado a foodstore. Revisión previa y ANALYZE condicional.
-- No se ejecuta VACUUM FULL ni se modifica el contenido de las tablas.
SELECT relname AS tabla, n_live_tup, n_dead_tup, n_mod_since_analyze,
       last_vacuum, last_autovacuum, last_analyze, last_autoanalyze,
       CASE
         WHEN last_analyze IS NULL AND last_autoanalyze IS NULL
           THEN 'sin estadisticas ANALYZE registradas'
         WHEN n_mod_since_analyze > GREATEST(1000, CEIL(n_live_tup * 0.10))
           THEN 'mas de 1000 o 10% de filas modificadas'
         ELSE 'sin accion manual necesaria'
       END AS decision
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND relname IN ('categoria', 'cliente', 'producto', 'pedido', 'detalle_pedido')
ORDER BY relname;

DO $mantenimiento$
DECLARE
    t record;
BEGIN
    FOR t IN
      SELECT relname, n_live_tup, n_mod_since_analyze,
             last_analyze, last_autoanalyze
      FROM pg_stat_user_tables
      WHERE schemaname = 'public'
        AND relname IN ('categoria', 'cliente', 'producto', 'pedido', 'detalle_pedido')
    LOOP
      IF (t.last_analyze IS NULL AND t.last_autoanalyze IS NULL)
         OR t.n_mod_since_analyze > GREATEST(1000, CEIL(t.n_live_tup * 0.10)) THEN
        RAISE NOTICE 'ANALYZE public.%: estadísticas ausentes o desactualizadas', t.relname;
        EXECUTE format('ANALYZE public.%I', t.relname);
      ELSE
        RAISE NOTICE 'Sin ANALYZE manual para public.%: estadísticas suficientes', t.relname;
      END IF;
    END LOOP;
END
$mantenimiento$;

SELECT pg_stat_clear_snapshot();
SELECT relname AS tabla, n_live_tup, n_dead_tup, n_mod_since_analyze,
       last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND relname IN ('categoria', 'cliente', 'producto', 'pedido', 'detalle_pedido')
ORDER BY relname;
