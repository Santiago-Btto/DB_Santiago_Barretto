# Modelo documental - TP9, Unidad 7

## Correspondencia con Food Store real

La base de origen es `foodstore` (PostgreSQL 18.4). `pedido(id_pedido PK, fecha, id_cliente FK, forma_pago)` se une con `cliente(id_cliente PK, nombre, apellido)` y `detalle_pedido(id_pedido FK, id_producto FK, cantidad, precio_unitario)`; `producto(id_producto PK, nombre, ...)` aporta el nombre actual del producto. Las claves foráneas observadas restringen el borrado de cliente, pedido y producto referenciados. Se seleccionaron 20 pedidos existentes y sus 40 líneas: los ocho que contienen el producto 100001 y doce pedidos adicionales. Los clientes proceden de la carga sintética de TP3 (`@example.invalid`); se omitieron email y teléfono.

La tabla `pedido` **no tiene columna `estado`**. Cada documento lleva `estado: "sin_estado_en_origen"` y `estado_procedencia: "pedido_sin_columna_estado"`. Es una marca de ausencia para la consulta requerida, no un estado comercial inventado. `forma_pago` conserva el valor real y se agrega una consulta selectiva adicional por ese campo.

| Origen PostgreSQL | Colección `foodstore_tp9.pedidos` | Decisión |
|---|---|---|
| `pedido.id_pedido` | `_id`, `id_pedido` como BSON `Long` | Identificador original y unicidad. |
| `pedido.fecha` | `fecha` como BSON `Date` + `fecha_pg_exacta` | El texto conserva microsegundos de PostgreSQL; BSON Date almacena milisegundos. |
| `pedido.forma_pago` | `forma_pago` | Valor original sin reinterpretación. |
| `cliente` | `cliente {id_cliente, nombre, apellido}` | Datos sintéticos esenciales; sin contacto personal. |
| `detalle_pedido` | `lineas[] {id_producto, nombre_producto_actual, cantidad, precio_unitario, subtotal}` | Dos líneas por pedido, leídas junto con la cabecera. `precio_unitario` y `subtotal` son Decimal128. El nombre se marca como actual, no histórico. |
| Suma de `cantidad * precio_unitario` | `total` como Decimal128 | Valor calculado desde precios históricos, sin usar el precio de lista actual. |

## Integridad y elección de embebidos

1. Cada línea debe tener `cantidad > 0`, `precio_unitario >= 0` y `subtotal = cantidad * precio_unitario`; `total` debe sumar los subtotales. La validación de colección impide cantidades no positivas y precios negativos. El script de migración verifica además las igualdades aritméticas en centavos enteros antes de insertar. La prueba controlada de `cantidad = 0` fue rechazada por MongoDB sin dejar un documento extra.
2. Los IDs de pedido son únicos y coinciden con PostgreSQL; cada línea y cliente procede de relaciones con claves foráneas. MongoDB no sustituye automáticamente esas referencias con claves foráneas entre colecciones: se comprueba la exportación completa y el origen relacional sigue siendo la fuente autorizada.

Se embeben cliente y líneas porque el acceso frecuente es al pedido completo, las dos líneas de esta muestra son acotadas y el precio histórico pertenece a la línea. No se migra todo el catálogo ni se afirma que el diseño sirva para arreglos de tamaño ilimitado: MongoDB limita cada documento a 16 MiB. La colección tiene índices por ID, estado, producto embebido y total.

Fuentes: [modelo embebido de MongoDB](https://www.mongodb.com/docs/manual/data-modeling/embedding/), [límite de arreglos](https://www.mongodb.com/docs/manual/data-modeling/design-antipatterns/unbounded-arrays/) y [restricciones de PostgreSQL](https://www.postgresql.org/docs/18/ddl-constraints.html).
