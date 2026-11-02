-- TP9 / Unidad 7. Ejecutar conectado a foodstore con psql -X -At -f.
-- Devuelve 20 documentos Extended JSON, una linea por pedido.
-- Los IDs se eligieron de la carga sintética de TP3: ocho pedidos con
-- producto 100001 y doce pedidos adicionales sin ese producto.
-- pedido no posee columna estado: el valor explicito es una etiqueta de
-- ausencia, no un estado de negocio inferido.
SELECT jsonb_build_object(
    '_id', jsonb_build_object('$numberLong', p.id_pedido::text),
    'id_pedido', jsonb_build_object('$numberLong', p.id_pedido::text),
    'fecha', jsonb_build_object('$date',
        to_char(p.fecha AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')),
    'fecha_pg_exacta', p.fecha::text,
    'estado', 'sin_estado_en_origen',
    'estado_procedencia', 'pedido_sin_columna_estado',
    'forma_pago', p.forma_pago::text,
    'cliente', jsonb_build_object(
        'id_cliente', jsonb_build_object('$numberLong', c.id_cliente::text),
        'nombre', c.nombre,
        'apellido', c.apellido
    ),
    'lineas', (
        SELECT jsonb_agg(jsonb_build_object(
            'id_producto', jsonb_build_object('$numberLong', d.id_producto::text),
            'nombre_producto_actual', pr.nombre,
            'cantidad', jsonb_build_object('$numberInt', d.cantidad::text),
            'precio_unitario', jsonb_build_object('$numberDecimal', d.precio_unitario::text),
            'subtotal', jsonb_build_object('$numberDecimal',
                (d.cantidad * d.precio_unitario)::text)
        ) ORDER BY d.id_producto)
        FROM detalle_pedido d
        JOIN producto pr ON pr.id_producto = d.id_producto
        WHERE d.id_pedido = p.id_pedido
    ),
    'total', jsonb_build_object('$numberDecimal', (
        SELECT SUM(d.cantidad * d.precio_unitario)::text
        FROM detalle_pedido d WHERE d.id_pedido = p.id_pedido
    ))
)::text AS documento
FROM pedido p
JOIN cliente c ON c.id_cliente = p.id_cliente
WHERE p.id_pedido IN (
    400001, 400002, 400003, 400004, 400005, 400006, 400007,
    400008, 400009, 400010, 400011, 400012, 400013,
    405882, 450001, 455882, 500001, 505882, 550001, 555882
)
AND EXISTS (SELECT 1 FROM detalle_pedido d WHERE d.id_pedido = p.id_pedido)
ORDER BY p.id_pedido;
