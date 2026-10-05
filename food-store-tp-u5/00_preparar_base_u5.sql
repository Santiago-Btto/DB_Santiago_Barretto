-- TP Unidad 5 - Preparacion exclusiva de la copia food_store_tp_u5_seguridad.
-- Nunca ejecutar sobre practica_bd2 ni sobre copias de TPs anteriores.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS usuario (
    id_usuario BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE,
    rol_negocio VARCHAR(40) NOT NULL,
    fecha_alta TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    password_hash TEXT NOT NULL,
    CONSTRAINT ck_usuario_nombre_no_vacio CHECK (btrim(nombre) <> ''),
    CONSTRAINT ck_usuario_apellido_no_vacio CHECK (btrim(apellido) <> ''),
    CONSTRAINT ck_usuario_rol_negocio CHECK (rol_negocio IN ('SOPORTE', 'OPERACIONES', 'REPORTES', 'CLIENTE'))
);

CREATE TABLE IF NOT EXISTS auditoria_evento (
    id_evento BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ocurrido_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    usuario_sesion NAME NOT NULL DEFAULT session_user,
    tipo_evento VARCHAR(60) NOT NULL,
    exitoso BOOLEAN,
    objeto_afectado VARCHAR(100) NOT NULL,
    detalle TEXT,
    aplicacion TEXT DEFAULT current_setting('application_name', true),
    ip_origen INET DEFAULT inet_client_addr()
);

INSERT INTO usuario (nombre, apellido, email, rol_negocio, fecha_alta, password_hash)
VALUES
    ('Ana', 'Diaz', 'ana.diaz@foodstore.test', 'OPERACIONES', '2026-01-15 10:00:00-03', crypt('LAB-TPU5-2026', gen_salt('bf'))),
    ('Bruno', 'Lopez', 'bruno.lopez@foodstore.test', 'REPORTES', '2026-02-10 10:00:00-03', crypt('LAB-TPU5-2026', gen_salt('bf'))),
    ('Carla', 'Suarez', 'operador.soporte@foodstore.test', 'SOPORTE', '2026-03-20 10:00:00-03', crypt('LAB-TPU5-2026', gen_salt('bf')))
ON CONFLICT (email) DO UPDATE
SET nombre = EXCLUDED.nombre,
    apellido = EXCLUDED.apellido,
    rol_negocio = EXCLUDED.rol_negocio,
    fecha_alta = EXCLUDED.fecha_alta,
    password_hash = EXCLUDED.password_hash;

-- Usuarios sinteticos: permiten reproducir una lectura masiva y verificar
-- agregados sin usar datos personales reales.
INSERT INTO usuario (nombre, apellido, email, rol_negocio, fecha_alta, password_hash)
SELECT 'Usuario' || gs,
       'Sintetico' || gs,
       format('usuario_%s@foodstore.test', gs),
       (ARRAY['SOPORTE', 'OPERACIONES', 'REPORTES', 'CLIENTE'])[(gs % 4) + 1],
       date_trunc('month', TIMESTAMPTZ '2025-01-01 00:00:00-03')
         + ((gs % 18) * INTERVAL '1 month'),
       crypt('NO-LOGIN-TPU5', gen_salt('bf'))
FROM generate_series(1, 1200) AS gs
ON CONFLICT (email) DO NOTHING;

CREATE OR REPLACE FUNCTION fn_autenticar(p_email TEXT, p_password TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    autenticado BOOLEAN;
BEGIN
    SELECT password_hash = crypt(p_password, password_hash)
      INTO autenticado
      FROM usuario
     WHERE email = p_email;

    autenticado := coalesce(autenticado, FALSE);

    INSERT INTO auditoria_evento (tipo_evento, exitoso, objeto_afectado, detalle)
    VALUES ('AUTENTICACION_APLICACION', autenticado, 'usuario', 'identificador=' || p_email);

    RETURN autenticado;
END;
$$;

CREATE OR REPLACE FUNCTION fn_resetear_password(p_email TEXT, p_nueva_password TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    UPDATE usuario
       SET password_hash = crypt(p_nueva_password, gen_salt('bf'))
     WHERE email = p_email;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario inexistente';
    END IF;

    INSERT INTO auditoria_evento (tipo_evento, exitoso, objeto_afectado, detalle)
    VALUES ('RESETEO_PASSWORD', TRUE, 'usuario', 'identificador=' || p_email);
END;
$$;

CREATE OR REPLACE VIEW vw_u5_ventas_categoria AS
SELECT c.id_categoria,
       c.nombre AS categoria,
       count(dp.id_producto) AS lineas_vendidas,
       coalesce(sum(dp.cantidad * dp.precio_unitario), 0) AS total_vendido
FROM categoria AS c
LEFT JOIN producto AS p ON p.id_categoria = c.id_categoria
LEFT JOIN detalle_pedido AS dp ON dp.id_producto = p.id_producto
GROUP BY c.id_categoria, c.nombre;

ANALYZE usuario;
ANALYZE auditoria_evento;

COMMIT;

SELECT current_database() AS base_preparada,
       (SELECT count(*) FROM usuario) AS usuarios_laboratorio,
       (SELECT count(*) FROM usuario WHERE email = 'operador.soporte@foodstore.test') AS cuenta_simulacro;
