-- Ejecutar únicamente en la copia PostgreSQL foodstore_tp10_u8.
BEGIN;
DO $$
BEGIN
  IF current_database() <> 'foodstore_tp10_u8' THEN
    RAISE EXCEPTION 'La vista de Unidad 8 solo se crea en foodstore_tp10_u8';
  END IF;
END $$;

-- La base foodstore usada en TP9 es anterior a la migración TPI que agregó deleted_at.
-- La columna se agrega exclusivamente a esta copia para representar lápidas.
ALTER TABLE producto ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE OR REPLACE VIEW v_snapshot_movil AS
SELECT p.id_producto AS id,
       p.nombre,
       (p.precio_lista * 100)::BIGINT AS precio_centavos,
       p.stock AS stock_visto,
       CASE WHEN p.activo AND p.deleted_at IS NULL THEN 1 ELSE 0 END AS disponible,
       CASE WHEN p.deleted_at IS NOT NULL THEN 1 ELSE 0 END AS eliminado,
       to_char(clock_timestamp() AT TIME ZONE 'UTC',
               'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') AS fecha_copia
FROM producto p
WHERE p.id_producto IN (100001, 100002, 100003, 100004);
COMMIT;

-- Los cuatro IDs son una muestra sintética controlada para la feria. El 100001
-- también aparece en la migración documental del TP9, Unidad 7.
