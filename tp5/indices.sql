-- Índices aceptados de TP5.
-- Se completa incrementalmente: cada bloque está además en índices/ para que el
-- historial de Git muestre la decisión individual y su medición correspondiente.

-- Q1: el filtro selectivo por producto queda primero y el pedido conserva el orden.
-- INCLUDE permite devolver cantidad y precio sin ampliar la clave de búsqueda.
CREATE INDEX idx_tp5_detalle_producto_pedido
    ON detalle_pedido (id_producto, id_pedido)
    INCLUDE (cantidad, precio_unitario);

ANALYZE detalle_pedido;
