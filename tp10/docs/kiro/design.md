# Diseño breve - Food Store tablet

## Límites y fuentes

- PostgreSQL `foodstore` es la fuente de verdad. Se clona a `foodstore_tp10_u8` para el laboratorio y sólo se modifican precio, stock y baja lógica de productos en esa copia. `pedido` no se escribe desde SQLite.
- La vista `v_snapshot_movil` toma cuatro productos sintéticos de la carga usada en TP9 (incluye `100001`). Exporta ID, nombre, precio en centavos enteros, stock visto, disponibilidad, lápida y hora de copia. No exporta clientes, usuarios, contraseñas ni correos.
- SQLite guarda caché, borradores, ítems, cola y la última instantánea. Las tablas de negocio son `STRICT`, activan claves foráneas y usan restricciones `CHECK`.
- MongoDB de TP9 sigue siendo una copia documental de pedidos para lectura y comparación. No recibe ni aprueba solicitudes de la tablet.

## Flujo

1. Exportar la vista de la copia PostgreSQL a CSV e importarla en `snapshot_servidor`; actualizar `producto_cache` sin eliminar filas dadas de baja (lápidas).
2. Crear el borrador y su UUID local en una transacción. Una solicitud en `cola_sync` referencia el borrador.
3. El semáforo agrega problemas por solicitud pendiente. Prioridad: rojo por ausencia, indisponibilidad, baja o stock insuficiente; amarillo por precio diferente; verde por coincidencia. La decisión sólo cambia `cola_sync`.
4. El usuario resuelve un conflicto creando un UUID de solicitud nuevo; el historial anterior permanece. Un UUID duplicado falla por clave primaria.

La comparación usa exclusivamente la instantánea del servidor. En un sistema real, la validación final y la idempotencia estarían en una transacción del servidor, con una tabla de solicitudes únicas y actualización condicionada de stock.
