-- TP Unidad 4 - Preparacion exclusiva de la copia de laboratorio.
-- Ejecutar UNA sola vez en food_store_tp_u4_fnbc, nunca en practica_bd2
-- ni en las bases usadas para TP3, TP4, TP5 o TPI.

BEGIN;

-- La guia de U4 usa eliminado y subtotal en su consulta de referencia.
-- Se agregan solamente en la copia aislada para conservar compatibilidad
-- con el modelo Food Store que se venia utilizando.
ALTER TABLE pedido
    ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE detalle_pedido
    ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE detalle_pedido
    ADD COLUMN IF NOT EXISTS subtotal NUMERIC(14,2)
    GENERATED ALWAYS AS (cantidad * precio_unitario) STORED;

-- La carga masiva historica termina antes de la fecha actual. Se desplaza
-- solo en esta copia para que CURRENT_DATE represente un dia real de ventas
-- y EXPLAIN ANALYZE mida trabajo efectivo.
WITH fecha_referencia AS (
    SELECT max(fecha::date) AS fecha_maxima
    FROM pedido
)
UPDATE pedido AS ped
SET fecha = ped.fecha + ((CURRENT_DATE - ref.fecha_maxima) * INTERVAL '1 day')
FROM fecha_referencia AS ref
WHERE ref.fecha_maxima IS NOT NULL
  AND ref.fecha_maxima <> CURRENT_DATE;

ANALYZE categoria;
ANALYZE producto;
ANALYZE pedido;
ANALYZE detalle_pedido;

COMMIT;

SELECT current_database() AS base_preparada,
       CURRENT_DATE AS fecha_reporte,
       (SELECT count(*) FROM pedido WHERE fecha::date = CURRENT_DATE) AS pedidos_hoy,
       (SELECT count(*) FROM detalle_pedido AS dp
        JOIN pedido AS ped ON ped.id_pedido = dp.id_pedido
        WHERE ped.fecha::date = CURRENT_DATE
          AND NOT dp.eliminado
          AND NOT ped.eliminado) AS detalles_hoy;
