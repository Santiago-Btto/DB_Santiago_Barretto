-- TP Unidad 5 - Parte B: configuracion y prueba de auditoria nativa.
-- Ejecutar como postgres y solo en el servidor local de desarrollo.

ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u,db=%d,app=%a,client=%r ';
SELECT pg_reload_conf();
SELECT pg_sleep(1);

SELECT name, setting, source
FROM pg_settings
WHERE name IN ('log_connections', 'log_disconnections', 'log_statement', 'log_line_prefix', 'logging_collector', 'log_directory', 'log_filename')
ORDER BY name;

-- Operaciones de prueba ejecutadas como administrador para dejar trazas
-- adicionales en el log nativo. El runner tambien abre sesiones de roles.
SET application_name = 'tp_u5_auditoria_postgres';
SELECT count(*) AS lectura_catalogo FROM producto;
BEGIN;
INSERT INTO auditoria_evento (tipo_evento, exitoso, objeto_afectado, detalle)
VALUES ('PRUEBA_AUDITORIA', TRUE, 'auditoria_evento', 'insercion reversible de prueba');
UPDATE auditoria_evento
   SET detalle = 'actualizacion reversible de prueba'
 WHERE id_evento = currval(pg_get_serial_sequence('auditoria_evento', 'id_evento'));
ROLLBACK;

-- El intento de sesion fallida se ejecuta desde run_tp_u5.ps1 con un rol
-- inexistente. Eso permite obtener una entrada FATAL del servidor sin tocar
-- cuentas reales ni modificar pg_hba.conf.
