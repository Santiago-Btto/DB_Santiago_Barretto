-- TP Unidad 5 - Parte C: simulacro controlado.
-- Ejecutar como soporte_operador contra food_store_tp_u5_seguridad.
-- La cuenta solo toma el rol de soporte, que posee SELECT limitado por columna.

SET application_name = 'tp_u5_simulacro';
SET ROLE rol_soporte;

-- Tres intentos fallidos y uno exitoso contra la funcion de aplicacion.
SELECT fn_autenticar('operador.soporte@foodstore.test', 'CLAVE-INCORRECTA-1') AS intento_1;
SELECT fn_autenticar('operador.soporte@foodstore.test', 'CLAVE-INCORRECTA-2') AS intento_2;
SELECT fn_autenticar('operador.soporte@foodstore.test', 'CLAVE-INCORRECTA-3') AS intento_3;
SELECT fn_autenticar('operador.soporte@foodstore.test', 'LAB-TPU5-2026') AS intento_4;

-- Lectura masiva permitida solo de las tres columnas justificadas para soporte.
-- La subconsulta lee 1.000 filas, pero se devuelve un contador para no exponer
-- ni repetir el listado en la evidencia del repositorio.
SELECT count(*) AS filas_lectura_masiva
FROM (
    SELECT id_usuario, nombre, apellido
    FROM usuario
    ORDER BY id_usuario
    LIMIT 1000
) AS lectura;

-- Intento de escalamiento: debe fallar. El bloque captura el error para que
-- la secuencia pueda terminar y la evidencia conserve el resultado esperado.
DO $$
BEGIN
    EXECUTE 'GRANT admin_datos TO soporte_operador';
    RAISE EXCEPTION 'HALLAZGO: el escalamiento se permitio; revisar roles.sql';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'ESCALAMIENTO_BLOQUEADO: soporte_operador no puede otorgarse admin_datos';
END;
$$;

RESET ROLE;
