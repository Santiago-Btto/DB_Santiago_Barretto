-- PARTE 4 - Consulta comun de competencia para DBeaver.
-- Ejecutar antes y despues de 02_indices.sql en una copia de laboratorio.
EXPLAIN (ANALYZE, BUFFERS)
WITH parametros AS (
    SELECT max(fecha) AS referencia
    FROM pedido
)
SELECT cat.id_categoria,
       cat.nombre AS categoria,
       count(DISTINCT ped.id_pedido) AS pedidos,
       sum(det.cantidad * det.precio_unitario) AS facturacion_30_dias
FROM categoria AS cat
JOIN producto AS prod ON prod.id_categoria = cat.id_categoria
JOIN detalle_pedido AS det ON det.id_producto = prod.id_producto
JOIN pedido AS ped ON ped.id_pedido = det.id_pedido
CROSS JOIN parametros AS par
WHERE cat.activo
  AND prod.activo
  AND ped.fecha >= par.referencia - interval '30 days'
GROUP BY cat.id_categoria, cat.nombre
ORDER BY facturacion_30_dias DESC, cat.id_categoria ASC;
