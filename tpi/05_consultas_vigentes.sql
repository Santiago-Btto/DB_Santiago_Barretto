-- Consultas operativas del modelo TPI.
-- Ejecutar despues de 01_migracion_modelo_final.sql y 02_objetos_programables.sql.
-- Las consultas TP3, TP4 y TP5 conservan su evidencia historica previa al soft delete.

SELECT id_cliente, nombre, apellido, email
FROM vw_tpi_clientes_vigentes
ORDER BY apellido, nombre;

SELECT id_producto, nombre AS producto, categoria, precio_lista, stock
FROM vw_tpi_productos_vigentes
ORDER BY categoria, producto;

SELECT id_pedido, fecha, forma_pago, id_cliente, nombre, apellido
FROM vw_tpi_pedidos_cliente_vigentes
ORDER BY fecha DESC;

SELECT id_pedido, producto, cantidad, precio_unitario, subtotal
FROM vw_tpi_detalle_pedido_producto_vigente
ORDER BY id_pedido, producto;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_cliente, nombre, apellido, email
FROM vw_tpi_clientes_vigentes
WHERE apellido LIKE 'TP3%'
ORDER BY apellido, nombre;
