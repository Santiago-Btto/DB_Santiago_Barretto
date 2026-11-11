-- Ajuste de mínimo privilegio para la base de laboratorio de Unidad 5.
\set ON_ERROR_STOP on
BEGIN;
DO $$
BEGIN
  IF current_database() <> 'food_store_tp_u5_seguridad' THEN
    RAISE EXCEPTION 'La corrección sólo aplica a food_store_tp_u5_seguridad';
  END IF;
  IF to_regclass('public.auditoria_evento') IS NULL THEN
    RAISE EXCEPTION 'Falta auditoria_evento';
  END IF;
END $$;
REVOKE INSERT, UPDATE, DELETE ON auditoria_evento FROM admin_datos;
GRANT SELECT ON auditoria_evento TO admin_datos;
COMMIT;
SELECT privilege_type, has_table_privilege('admin_datos', 'auditoria_evento', privilege_type)
FROM (VALUES ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE')) AS p(privilege_type)
ORDER BY privilege_type;
