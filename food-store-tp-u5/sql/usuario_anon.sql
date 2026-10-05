-- TP Unidad 5 - Parte D: anonimización determinista y equivalencia agregada.

BEGIN;

DROP TABLE IF EXISTS usuario_anon;
CREATE TABLE usuario_anon (
    id_usuario BIGINT PRIMARY KEY,
    nombre_sintetico VARCHAR(100) NOT NULL,
    apellido_sintetico VARCHAR(100) NOT NULL,
    email_sintetico VARCHAR(254) NOT NULL UNIQUE,
    rol_negocio VARCHAR(40) NOT NULL,
    fecha_alta TIMESTAMPTZ NOT NULL
);

INSERT INTO usuario_anon (
    id_usuario, nombre_sintetico, apellido_sintetico, email_sintetico, rol_negocio, fecha_alta
)
SELECT id_usuario,
       'Usuario_' || id_usuario,
       'Anonimo_' || id_usuario,
       'anon_' || id_usuario || '@ejemplo.invalid',
       rol_negocio,
       fecha_alta
FROM usuario;

COMMIT;

-- Resultado agregado de la fuente real.
SELECT 'REAL' AS origen,
       rol_negocio,
       date_trunc('month', fecha_alta)::date AS mes_alta,
       count(*) AS usuarios
FROM usuario
GROUP BY rol_negocio, date_trunc('month', fecha_alta)::date
ORDER BY rol_negocio, mes_alta;

-- Resultado agregado equivalente sobre datos anonimizados.
SELECT 'ANONIMIZADO' AS origen,
       rol_negocio,
       date_trunc('month', fecha_alta)::date AS mes_alta,
       count(*) AS usuarios
FROM usuario_anon
GROUP BY rol_negocio, date_trunc('month', fecha_alta)::date
ORDER BY rol_negocio, mes_alta;

-- Verificacion formal: ambas direcciones deben devolver cero filas.
WITH real AS (
    SELECT rol_negocio,
           date_trunc('month', fecha_alta)::date AS mes_alta,
           count(*) AS usuarios
    FROM usuario
    GROUP BY rol_negocio, date_trunc('month', fecha_alta)::date
),
anonimo AS (
    SELECT rol_negocio,
           date_trunc('month', fecha_alta)::date AS mes_alta,
           count(*) AS usuarios
    FROM usuario_anon
    GROUP BY rol_negocio, date_trunc('month', fecha_alta)::date
)
SELECT 'real_menos_anonimo' AS control, count(*) AS diferencias
FROM (SELECT * FROM real EXCEPT SELECT * FROM anonimo) AS d
UNION ALL
SELECT 'anonimo_menos_real', count(*)
FROM (SELECT * FROM anonimo EXCEPT SELECT * FROM real) AS d;
