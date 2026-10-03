-- TP Unidad 4 - Parte 2: desnormalizacion controlada del top diario.
-- Patron elegido: vista materializada mantenida sincronizada por triggers.
-- Ejecutar SOLO en food_store_tp_u4_fnbc, luego de 00_preparar_base_u4.sql.

BEGIN;

DROP TRIGGER IF EXISTS trg_tp_u4_refrescar_top_detalle ON detalle_pedido;
DROP TRIGGER IF EXISTS trg_tp_u4_refrescar_top_pedido ON pedido;
DROP TRIGGER IF EXISTS trg_tp_u4_refrescar_top_producto ON producto;
DROP TRIGGER IF EXISTS trg_tp_u4_refrescar_top_categoria ON categoria;
DROP FUNCTION IF EXISTS fn_tp_u4_refrescar_top_categorias();
DROP MATERIALIZED VIEW IF EXISTS mv_tp_u4_top_categorias_dia;

-- Estructura redundante: una fila por dia y categoria. Evita recorrer las
-- cuatro tablas de la consulta de origen cuando el panel pide el top diario.
CREATE MATERIALIZED VIEW mv_tp_u4_top_categorias_dia AS
SELECT ped.fecha::date AS fecha,
       c.id_categoria,
       c.nombre AS categoria,
       sum(dp.subtotal) AS total_vendido
FROM detalle_pedido AS dp
JOIN producto AS pr ON pr.id_producto = dp.id_producto
JOIN categoria AS c ON c.id_categoria = pr.id_categoria
JOIN pedido AS ped ON ped.id_pedido = dp.id_pedido
WHERE dp.eliminado = FALSE
  AND ped.eliminado = FALSE
GROUP BY ped.fecha::date, c.id_categoria, c.nombre
WITH DATA;

-- La consulta del panel filtra por fecha y obtiene cinco filas ordenadas.
CREATE UNIQUE INDEX ux_mv_tp_u4_top_categorias_dia
    ON mv_tp_u4_top_categorias_dia (fecha, id_categoria);
CREATE INDEX ix_mv_tp_u4_top_categorias_fecha_monto
    ON mv_tp_u4_top_categorias_dia (fecha, total_vendido DESC);

-- Cada cambio relevante refresca la estructura dentro de la misma
-- transaccion. Si la transaccion se revierte, tambien se revierte el refresh:
-- no hay una ventana en la que el reporte confirme datos desincronizados.
CREATE FUNCTION fn_tp_u4_refrescar_top_categorias()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_tp_u4_top_categorias_dia;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_tp_u4_refrescar_top_detalle
AFTER INSERT OR UPDATE OR DELETE ON detalle_pedido
FOR EACH STATEMENT
EXECUTE FUNCTION fn_tp_u4_refrescar_top_categorias();

CREATE TRIGGER trg_tp_u4_refrescar_top_pedido
AFTER INSERT OR UPDATE OR DELETE ON pedido
FOR EACH STATEMENT
EXECUTE FUNCTION fn_tp_u4_refrescar_top_categorias();

CREATE TRIGGER trg_tp_u4_refrescar_top_producto
AFTER INSERT OR UPDATE OR DELETE ON producto
FOR EACH STATEMENT
EXECUTE FUNCTION fn_tp_u4_refrescar_top_categorias();

CREATE TRIGGER trg_tp_u4_refrescar_top_categoria
AFTER INSERT OR UPDATE OR DELETE ON categoria
FOR EACH STATEMENT
EXECUTE FUNCTION fn_tp_u4_refrescar_top_categorias();

COMMIT;

-- ANTES: consulta normalizada exacta de la guia, adaptada al nombre de las
-- columnas del modelo Food Store (id_producto, id_categoria e id_pedido).
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT c.nombre AS categoria,
       sum(dp.subtotal) AS total_vendido
FROM detalle_pedido AS dp
JOIN producto AS pr ON pr.id_producto = dp.id_producto
JOIN categoria AS c ON c.id_categoria = pr.id_categoria
JOIN pedido AS ped ON ped.id_pedido = dp.id_pedido
WHERE ped.fecha::date = CURRENT_DATE
  AND dp.eliminado = FALSE
  AND ped.eliminado = FALSE
GROUP BY c.nombre
ORDER BY total_vendido DESC
LIMIT 5;

-- DESPUES: mismo reporte leido directamente de la estructura desnormalizada.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT categoria, total_vendido
FROM mv_tp_u4_top_categorias_dia
WHERE fecha = CURRENT_DATE
ORDER BY total_vendido DESC
LIMIT 5;

-- Auditoria: debe devolver cero filas. Compara la fuente normalizada completa
-- contra la vista materializada, incluso si una de ambas tuviera una fila extra.
WITH fuente AS (
    SELECT ped.fecha::date AS fecha,
           c.id_categoria,
           c.nombre AS categoria,
           sum(dp.subtotal) AS total_vendido
    FROM detalle_pedido AS dp
    JOIN producto AS pr ON pr.id_producto = dp.id_producto
    JOIN categoria AS c ON c.id_categoria = pr.id_categoria
    JOIN pedido AS ped ON ped.id_pedido = dp.id_pedido
    WHERE dp.eliminado = FALSE
      AND ped.eliminado = FALSE
    GROUP BY ped.fecha::date, c.id_categoria, c.nombre
),
comparacion AS (
    SELECT coalesce(f.fecha, mv.fecha) AS fecha,
           coalesce(f.id_categoria, mv.id_categoria) AS id_categoria,
           f.categoria AS categoria_fuente,
           mv.categoria AS categoria_materializada,
           f.total_vendido AS total_fuente,
           mv.total_vendido AS total_materializado
    FROM fuente AS f
    FULL OUTER JOIN mv_tp_u4_top_categorias_dia AS mv
      ON mv.fecha = f.fecha
     AND mv.id_categoria = f.id_categoria
)
SELECT *
FROM comparacion
WHERE categoria_fuente IS DISTINCT FROM categoria_materializada
   OR total_fuente IS DISTINCT FROM total_materializado
ORDER BY fecha, id_categoria;

-- Prueba reversible del mecanismo de sincronizacion. La auditoria devuelve
-- cero filas dentro de la transaccion y ROLLBACK deja la copia como estaba.
BEGIN;
WITH nuevo_pedido AS (
    INSERT INTO pedido (fecha, id_cliente, forma_pago)
    SELECT CURRENT_DATE,
           (SELECT id_cliente FROM cliente ORDER BY id_cliente LIMIT 1),
           'EFECTIVO'::forma_pago_enum
    RETURNING id_pedido
)
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT np.id_pedido,
       (SELECT id_producto FROM producto WHERE activo ORDER BY id_producto LIMIT 1),
       1,
       (SELECT precio_lista FROM producto WHERE activo ORDER BY id_producto LIMIT 1)
FROM nuevo_pedido AS np;

WITH fuente AS (
    SELECT ped.fecha::date AS fecha,
           c.id_categoria,
           c.nombre AS categoria,
           sum(dp.subtotal) AS total_vendido
    FROM detalle_pedido AS dp
    JOIN producto AS pr ON pr.id_producto = dp.id_producto
    JOIN categoria AS c ON c.id_categoria = pr.id_categoria
    JOIN pedido AS ped ON ped.id_pedido = dp.id_pedido
    WHERE dp.eliminado = FALSE
      AND ped.eliminado = FALSE
    GROUP BY ped.fecha::date, c.id_categoria, c.nombre
)
SELECT 'auditoria_durante_prueba' AS control,
       count(*) AS diferencias
FROM (
    SELECT coalesce(f.fecha, mv.fecha) AS fecha,
           coalesce(f.id_categoria, mv.id_categoria) AS id_categoria,
           f.categoria AS categoria_fuente,
           mv.categoria AS categoria_materializada,
           f.total_vendido AS total_fuente,
           mv.total_vendido AS total_materializado
    FROM fuente AS f
    FULL OUTER JOIN mv_tp_u4_top_categorias_dia AS mv
      ON mv.fecha = f.fecha
     AND mv.id_categoria = f.id_categoria
    WHERE f.categoria IS DISTINCT FROM mv.categoria
       OR f.total_vendido IS DISTINCT FROM mv.total_vendido
) AS diferencias;

ROLLBACK;
