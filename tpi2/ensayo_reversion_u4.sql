-- Ensayo no destructivo de la reversión de FNBC en la copia de Unidad 4.
-- Ejecutar con psql -X -v ON_ERROR_STOP=1 -d food_store_tp_u4_fnbc -f ...
\set ON_ERROR_STOP on
BEGIN;
DO $$
BEGIN
  IF current_database() <> 'food_store_tp_u4_fnbc' THEN
    RAISE EXCEPTION 'Sólo se permite la copia food_store_tp_u4_fnbc';
  END IF;
  IF to_regclass('public.control_lote_almacen') IS NULL
     OR to_regclass('public.vw_control_lote_almacen_compatibilidad') IS NULL THEN
    RAISE EXCEPTION 'Falta el origen o la vista de compatibilidad';
  END IF;
  IF EXISTS (
    (SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen
     EXCEPT SELECT lote_id, deposito_id, responsable_control_id FROM vw_control_lote_almacen_compatibilidad)
    UNION ALL
    (SELECT lote_id, deposito_id, responsable_control_id FROM vw_control_lote_almacen_compatibilidad
     EXCEPT SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen)
  ) THEN
    RAISE EXCEPTION 'Diferencias entre origen y vista: no revertir';
  END IF;
  IF EXISTS (
    SELECT responsable_control_id FROM control_lote_almacen
    GROUP BY responsable_control_id HAVING count(DISTINCT deposito_id) > 1
  ) THEN
    RAISE EXCEPTION 'La dependencia funcional no se cumple';
  END IF;
END $$;
SELECT 'filas_originales', count(*) FROM control_lote_almacen;
DROP VIEW vw_control_lote_almacen_compatibilidad;
DROP TABLE control_lote_responsable;
DROP TABLE responsable_deposito;
SELECT 'origen_tras_reversion', count(*) FROM control_lote_almacen;
-- Se ensaya la reversión y se conserva el estado migrado.
ROLLBACK;
SELECT 'vista_restaurada', to_regclass('public.vw_control_lote_almacen_compatibilidad') IS NOT NULL;
SELECT 'tabla_original_preservada', count(*) FROM control_lote_almacen;
