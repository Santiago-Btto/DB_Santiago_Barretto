-- Ejecutar tanto en foodstore como en foodstore_restore_test.
-- El formato de salida para los scripts es psql -X -At -F '|'.
SELECT control, filas
FROM (
    SELECT 'categoria'::text AS control, COUNT(*)::bigint AS filas FROM public.categoria
    UNION ALL SELECT 'cliente', COUNT(*) FROM public.cliente
    UNION ALL SELECT 'producto', COUNT(*) FROM public.producto
    UNION ALL SELECT 'pedido', COUNT(*) FROM public.pedido
    UNION ALL SELECT 'detalle_pedido', COUNT(*) FROM public.detalle_pedido
    UNION ALL SELECT 'productos_invalidos', COUNT(*) FROM public.producto
      WHERE precio_lista < 0 OR stock < 0
    UNION ALL SELECT 'detalles_invalidos', COUNT(*) FROM public.detalle_pedido
      WHERE cantidad <= 0 OR precio_unitario < 0
) AS controles
ORDER BY control;
