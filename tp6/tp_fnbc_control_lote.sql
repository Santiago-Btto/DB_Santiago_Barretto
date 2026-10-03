-- TP Unidad 4 - Parte 1: FNBC para ControlLoteAlmacen.
-- Ejecutar en la copia food_store_tp_u4_fnbc despues de 00_preparar_base_u4.sql.

BEGIN;

-- Tablas maestras minimas de la extension mayorista descripta en la guia.
CREATE TABLE IF NOT EXISTS lote (
    id BIGINT PRIMARY KEY,
    codigo VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS deposito (
    id BIGINT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS usuario (
    id BIGINT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL
);

INSERT INTO lote (id, codigo) VALUES
    (501, 'L-501'),
    (502, 'L-502'),
    (503, 'L-503')
ON CONFLICT (id) DO NOTHING;

INSERT INTO deposito (id, nombre) VALUES
    (30, 'Deposito Norte'),
    (31, 'Deposito Sur')
ON CONFLICT (id) DO NOTHING;

INSERT INTO usuario (id, nombre) VALUES
    (801, 'Responsable 801'),
    (802, 'Responsable 802')
ON CONFLICT (id) DO NOTHING;

-- Esquema original: admite la PK de la guia, pero no expresa la DF
-- ResponsableControlID -> DepositoID. Por eso no esta en FNBC.
CREATE TABLE IF NOT EXISTS control_lote_almacen (
    lote_id BIGINT NOT NULL REFERENCES lote(id),
    deposito_id BIGINT NOT NULL REFERENCES deposito(id),
    responsable_control_id BIGINT NOT NULL REFERENCES usuario(id),
    PRIMARY KEY (lote_id, deposito_id)
);

INSERT INTO control_lote_almacen (lote_id, deposito_id, responsable_control_id) VALUES
    (501, 30, 801),
    (502, 30, 801),
    (503, 31, 802)
ON CONFLICT (lote_id, deposito_id) DO NOTHING;

-- Verificacion SQL de la DF ResponsableControlID -> DepositoID.
-- Debe devolver cero filas: un responsable no puede aparecer en dos depositos.
SELECT responsable_control_id
FROM control_lote_almacen
GROUP BY responsable_control_id
HAVING count(DISTINCT deposito_id) > 1;

-- Descomposicion por la DF violatoria:
-- R1(ResponsableControlID, DepositoID) y R2(LoteID, ResponsableControlID).
CREATE TABLE IF NOT EXISTS responsable_deposito (
    responsable_control_id BIGINT PRIMARY KEY REFERENCES usuario(id),
    deposito_id BIGINT NOT NULL REFERENCES deposito(id)
);

CREATE TABLE IF NOT EXISTS control_lote_responsable (
    lote_id BIGINT NOT NULL REFERENCES lote(id),
    responsable_control_id BIGINT NOT NULL REFERENCES responsable_deposito(responsable_control_id),
    PRIMARY KEY (lote_id, responsable_control_id)
);

INSERT INTO responsable_deposito (responsable_control_id, deposito_id)
SELECT responsable_control_id, min(deposito_id) AS deposito_id
FROM control_lote_almacen
GROUP BY responsable_control_id
ON CONFLICT (responsable_control_id) DO UPDATE
SET deposito_id = EXCLUDED.deposito_id;

INSERT INTO control_lote_responsable (lote_id, responsable_control_id)
SELECT lote_id, responsable_control_id
FROM control_lote_almacen
ON CONFLICT (lote_id, responsable_control_id) DO NOTHING;

CREATE OR REPLACE VIEW vw_control_lote_almacen_compatibilidad AS
SELECT lote_id, deposito_id, responsable_control_id
FROM control_lote_responsable
NATURAL JOIN responsable_deposito;

COMMIT;

-- Equivalencia de la migracion: ambos EXCEPT deben devolver cero filas.
SELECT 'original_menos_vista' AS control, count(*) AS diferencias
FROM (
    SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen
    EXCEPT
    SELECT lote_id, deposito_id, responsable_control_id FROM vw_control_lote_almacen_compatibilidad
) AS diferencias
UNION ALL
SELECT 'vista_menos_original', count(*)
FROM (
    SELECT lote_id, deposito_id, responsable_control_id FROM vw_control_lote_almacen_compatibilidad
    EXCEPT
    SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen
) AS diferencias;

SELECT *
FROM vw_control_lote_almacen_compatibilidad
ORDER BY lote_id;
