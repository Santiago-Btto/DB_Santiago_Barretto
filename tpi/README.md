# TPI - Food Store

Esta carpeta completa la primera entrega parcial del Trabajo Práctico Integrador. Integra los contenidos de integridad y concurrencia (TP2), optimización (TP3 y TP4) e índices, vistas y materialización (TP5) sobre PostgreSQL 16+; las pruebas de esta revisión se ejecutaron con PostgreSQL 18.4.

## Ejecución en una copia aislada

1. Crear una base de laboratorio desde `schema.sql` o clonar la base de trabajo actual.
2. Si la base proviene del esquema anterior, ejecutar `01_migracion_modelo_final.sql`. Sus controles previos deben devolver cero filas.
3. Ejecutar `02_objetos_programables.sql`.
4. Ejecutar `03_pruebas_objetos.sql`; finaliza con `ROLLBACK`, por lo que valida sin dejar filas de demostración.
5. Ejecutar `05_consultas_vigentes.sql` para los reportes operativos que respetan el borrado lógico.
6. Consultar `evidencia/` para las salidas reales y `docs/04_checklist_tpi.md` para el mapa completo de requisitos.

Los TPs anteriores se conservan sin reescribir sus mediciones históricas. Las cuatro vistas `vw_tpi_*_vigentes` son el punto de acceso de las consultas nuevas que no deben incluir filas dadas de baja.

## Objetos creados

- `sp_tpi_registrar_pedido`: procedimiento atómico que bloquea el producto, comprueba stock y genera pedido más detalle.
- `sp_tpi_baja_logica_cliente` y `sp_tpi_baja_logica_producto`: bajas lógicas mediante `deleted_at`; la de producto también lo inactiva.
- `trg_tpi_detalle_producto_vigente`: no permite agregar a un pedido un producto inactivo o dado de baja.
- `trg_tpi_auditoria_producto`: registra inserciones, modificaciones y eliminaciones de productos.
- Cuatro vistas `vw_tpi_*_vigentes`: clientes, productos, pedidos con cliente y detalle con producto; filtran bajas lógicas. La de clientes no expone teléfono.

El rol sin login `food_store_reporter` recibe `SELECT` solo sobre las vistas TPI y ningún privilegio directo sobre `cliente` o `producto`. El runner de concurrencia admite `-PsqlPath`; si `psql` está en `PATH`, no depende de una instalación concreta.
