-- TP Unidad 5 - Parte A: roles y permisos de minimo privilegio.
-- Requiere ejecutar antes 00_preparar_base_u5.sql en food_store_tp_u5_seguridad.
-- Los roles son objetos del servidor PostgreSQL; los privilegios sobre tablas
-- quedan limitados a la base indicada en este laboratorio.

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_app_lectura') THEN
        CREATE ROLE rol_app_lectura NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_app_escritura') THEN
        CREATE ROLE rol_app_escritura NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_soporte') THEN
        CREATE ROLE rol_soporte NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_reportes') THEN
        CREATE ROLE rol_reportes NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_auditoria') THEN
        CREATE ROLE rol_auditoria NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_web') THEN
        CREATE ROLE app_web LOGIN NOINHERIT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'soporte_operador') THEN
        CREATE ROLE soporte_operador LOGIN NOINHERIT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_datos') THEN
        CREATE ROLE admin_datos LOGIN NOINHERIT;
    END IF;
END;
$$;

ALTER ROLE rol_app_lectura NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
ALTER ROLE rol_app_escritura NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
ALTER ROLE rol_soporte NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
ALTER ROLE rol_reportes NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
ALTER ROLE rol_auditoria NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
ALTER ROLE app_web LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
ALTER ROLE soporte_operador LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
ALTER ROLE admin_datos LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;

GRANT rol_app_lectura, rol_app_escritura TO app_web;
GRANT rol_soporte TO soporte_operador;

REVOKE ALL ON DATABASE food_store_tp_u5_seguridad FROM PUBLIC;
GRANT CONNECT ON DATABASE food_store_tp_u5_seguridad TO app_web, soporte_operador, admin_datos;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO rol_app_lectura, rol_app_escritura, rol_soporte, rol_reportes, rol_auditoria, app_web, soporte_operador, admin_datos;

-- Aplicacion: catalogos de lectura y altas/cambios de pedidos, sin acceso a usuario.
GRANT SELECT ON categoria, producto TO rol_app_lectura;
GRANT INSERT, UPDATE ON pedido, detalle_pedido TO rol_app_escritura;
GRANT SELECT (id_pedido) ON pedido TO rol_app_escritura;
GRANT USAGE, SELECT ON SEQUENCE pedido_id_pedido_seq TO rol_app_escritura;
GRANT EXECUTE ON FUNCTION fn_autenticar(TEXT, TEXT) TO rol_app_lectura;

-- Soporte: solo identifica usuarios para atender tickets y puede resetear una clave.
GRANT SELECT (id_usuario, nombre, apellido) ON usuario TO rol_soporte;
GRANT EXECUTE ON FUNCTION fn_autenticar(TEXT, TEXT), fn_resetear_password(TEXT, TEXT) TO rol_soporte;

-- Reportes: solo la vista agregada; no recibe tablas transaccionales.
GRANT SELECT ON vw_u5_ventas_categoria TO rol_reportes;

-- Auditoria: lectura de eventos tecnicos, sin acceso a usuarios ni contrasenas.
GRANT SELECT ON auditoria_evento TO rol_auditoria;

-- Administracion de datos: mantenimiento de usuario y consulta de auditoria,
-- sin privilegio de superusuario, creacion de roles ni lectura de hashes.
REVOKE ALL ON usuario FROM admin_datos;
GRANT SELECT (id_usuario, nombre, apellido, email, rol_negocio, fecha_alta) ON usuario TO admin_datos;
GRANT INSERT (nombre, apellido, email, rol_negocio, fecha_alta, password_hash) ON usuario TO admin_datos;
GRANT UPDATE (nombre, apellido, email, rol_negocio, fecha_alta) ON usuario TO admin_datos;
GRANT DELETE ON usuario TO admin_datos;
GRANT SELECT, INSERT, UPDATE, DELETE ON auditoria_evento TO admin_datos;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO admin_datos;
GRANT EXECUTE ON FUNCTION fn_autenticar(TEXT, TEXT), fn_resetear_password(TEXT, TEXT) TO admin_datos;

-- Politica por defecto: las tablas y funciones futuras no se exponen a PUBLIC.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON SEQUENCES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

SELECT rolname, rolcanlogin, rolinherit, rolsuper, rolcreaterole
FROM pg_roles
WHERE rolname IN ('rol_app_lectura', 'rol_app_escritura', 'rol_soporte', 'rol_reportes', 'rol_auditoria', 'app_web', 'soporte_operador', 'admin_datos')
ORDER BY rolname;
