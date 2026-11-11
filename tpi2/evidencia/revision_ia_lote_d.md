| ruta | revisado | hallazgo |
|---|---|---|
| tp5/00_preflight.sql | sí | sin hallazgo prioritario |
| tp5/01_consultas_frecuentes.sql | sí | sin hallazgo prioritario (prefijos compatibles con índices) |
| tp5/03_medicion_escritura.sql | sí | sin hallazgo prioritario (BEGIN/ROLLBACK correcto) |
| tp5/05_equivalencia_views.sql | sí | sin hallazgo prioritario (EXCEPT bidireccional) |
| tp5/07_medicion_materializada.sql | sí | sin hallazgo prioritario |
| tp5/08_refrescar_materializada.sql | sí | sin hallazgo prioritario (requiere índice único) |
| tp5/build_entrega_pdf.py | sí | métricas y refs (duia.md, registro_codex.md) no verificables en el lote |
| tp5/dbeaver/01_consultas_frecuentes.sql | sí | sin hallazgo prioritario |
| tp5/dbeaver/02_indices.sql | sí | sin hallazgo prioritario |
| tp5/dbeaver/03_medicion_escritura.sql | sí | omite conteo de filas y timing vs versión psql |
| tp5/dbeaver/04_views.sql | sí | sin hallazgo prioritario |
| tp5/dbeaver/06_materializadas.sql | sí | sin hallazgo prioritario |
| tp5/dbeaver/07_medicion_materializada.sql | sí | sin hallazgo prioritario |
| tp5/dbeaver/08_refrescar_materializada.sql | sí | sin hallazgo prioritario |
| tp5/indices.sql | sí | sin hallazgo prioritario (consolidado) |
| tp5/indices/01_detalle_producto_pedido.sql | sí | sin hallazgo prioritario |
| tp5/indices/02_producto_nombre_activo_prefijo.sql | sí | sin hallazgo prioritario |
| tp5/indices/03_cliente_apellido_prefijo.sql | sí | sin hallazgo prioritario |
| tp5/materializadas.sql | sí | sin hallazgo prioritario |
| tp5/materializadas/01_facturacion_categoria_mes.sql | sí | sin hallazgo prioritario |
| tp5/views.sql | sí | sin hallazgo prioritario |
| tp5/views/01_productos_vigentes_categoria.sql | sí | sin hallazgo prioritario |
| tp5/views/02_pedidos_cliente.sql | sí | sin hallazgo prioritario |
| tp5/views/03_detalle_pedido_producto.sql | sí | sin hallazgo prioritario |
| tp5/views/04_clientes_reportes.sql | sí | sin hallazgo prioritario (no expone teléfono) |

Hallazgos accionables:
1. Media — `tp5/build_entrega_pdf.py`: tiempos/factores y refs a `duia.md`/`registro_codex.md` no verificables en el lote. Propuesta: versionar EXPLAIN/mediciones y validar rutas.
2. Media — `tp5/dbeaver/03_medicion_escritura.sql`: no replica conteo ni timing de la versión psql. Propuesta: alinear o documentar método DBeaver.
3. Baja — numeración salta 02/04/06 en `tp5/`. Propuesta: documentar en README o renumerar.
4. Baja — `vw_tp5_clientes_reportes` mínimo privilegio solo se prueba por equivalencia. Propuesta: agregar aserción de columnas/permisos en `05_equivalencia_views.sql`.
