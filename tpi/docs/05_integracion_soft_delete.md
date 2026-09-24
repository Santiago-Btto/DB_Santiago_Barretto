# Integración del borrado lógico

## Regla operativa final

El modelo actual usa `deleted_at` en `cliente` y `producto`. Las bajas se realizan con `sp_tpi_baja_logica_cliente` y `sp_tpi_baja_logica_producto`; la segunda también deja `activo = FALSE`. Las consultas operativas deben usar las vistas `vw_tpi_*_vigentes` o el filtro explícito `deleted_at IS NULL`.

Los índices parciales `ux_cliente_email_vigente`, `idx_tpi_cliente_vigente_apellido_nombre` e `idx_tpi_producto_vigente_categoria` están alineados con ese filtro. El script `tpi/05_consultas_vigentes.sql` muestra los accesos actuales y no devuelve clientes o productos dados de baja.

## TPs históricos y modelo actual

Las evidencias de TP3, TP4 y TP5 se preservan como mediciones históricas realizadas antes de incorporar `deleted_at`; no se cambian sus SQL ni sus tiempos para no falsear planes ya versionados. Por eso, sus consultas y vistas históricas no son la interfaz operativa del modelo final.

Cuando se necesite ejecutar reportes sobre el esquema final, se usan las vistas de TPI. En particular, `vw_tpi_pedidos_cliente_vigentes` excluye pedidos de clientes dados de baja y `vw_tpi_detalle_pedido_producto_vigente` excluye productos inactivos o dados de baja. De esta manera el efecto del ciclo de vida queda explícito y no se mezcla con las mediciones anteriores.

## Unicidad de email

La validación histórica de TP3 detectaba cualquier email repetido porque el modelo original imponía unicidad global. En el modelo final, la regla correcta es unicidad solo entre clientes vigentes: `ux_cliente_email_vigente` permite conservar el historial de una baja y reutilizar el email para una nueva alta. Las verificaciones nuevas deben aplicar `WHERE deleted_at IS NULL` antes de agrupar por email.
