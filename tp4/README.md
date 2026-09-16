# TP4 - Reportes analiticos asistidos por IA sobre Food Store

Este directorio resuelve el TP4 sobre el esquema real del repositorio: `cliente`, `categoria`, `producto`, `pedido` y `detalle_pedido`. Los SQL no suponen columnas inexistentes: el borrado logico solo se filtra en `categoria.activo` y `producto.activo`, porque las demas tablas no tienen esa columna.

No hay tiempos, planes ni afirmaciones de mejora inventados. Las decisiones se completan unicamente luego de medir en la copia de laboratorio.

## Preparacion segura

Trabajar sobre una copia de la base masiva que ya contiene la carga del TP3. No ejecutar sobre `practica_bd2` ni sobre la base original. Antes de crear indices, realizar un backup desde DBeaver o con `pg_dump`.

## Orden de ejecucion

1. Abrir `00_preflight.sql` y confirmar en el resultado la base de laboratorio, sus tablas y sus indices.
2. Ejecutar `01_consultas_analiticas.sql` y guardar el texto completo de ambos `EXPLAIN (ANALYZE, BUFFERS)` como medicion **antes**.
3. Leer `02_indices.sql`; si se entiende cada indice, ejecutarlo y guardar su salida.
4. Ejecutar nuevamente `01_consultas_analiticas.sql`, ahora como medicion **despues**. Identificar en cada plan los `Hash Join`, `Nested Loop` o `Merge Join` reales; no adivinarlos por el SQL.
5. Ejecutar `03_specs_equivalencia.sql`. Las cuatro filas de control deben dar `0`.
6. Para la competencia, medir `04_consulta_comun_competencia.sql` antes y despues de la estrategia que se decida justificar. Registrar ambos tiempos.
7. Ejecutar `05_validacion.sql`: los controles de integridad y los cuatro controles de equivalencia deben dar `0`.

Para DBeaver usar los archivos equivalentes de `tp4/dbeaver/`; no contienen metacomandos de `psql`.

## Parte 1 - consultas medibles

| Consulta | Tablas / agregacion | Filtro selectivo | Indice candidato | Plan antes | Plan despues | Mejora |
|---|---|---|---|---|---|---|
| Q1 Facturacion por categoria y mes | pedido, detalle, producto, categoria; `SUM` y `COUNT(DISTINCT)` | ultimos 30 dias desde la fecha maxima cargada, categoria/producto activos | `idx_tp4_pedido_fecha_id_cliente` y cobertura de detalle | completar con nodos y ms reales | completar con nodos y ms reales | completar |
| Q2 Ranking de clientes por gasto | cliente, pedido, detalle, producto; `SUM` + `RANK()` | ultimos 30 dias desde la fecha maxima cargada, producto activo | mismos indices, sujeto al plan | completar con nodos y ms reales | completar con nodos y ms reales | completar |
| Q3 Ventas mensuales de producto 100001 | producto, categoria, detalle, pedido; `SUM` mensual | `id_producto = 100001`, producto/categoria activos | `idx_tp4_detalle_producto_pedido` | Parallel Seq Scan de `detalle_pedido`; 65.141 ms | Index Only Scan; 0.460 ms | 141.61x; aceptado |

Los indices de `02_indices.sql` son hipotesis revisables:

- `idx_tp4_pedido_fecha_id_cliente (fecha DESC, id_pedido) INCLUDE (id_cliente)` busca reducir las filas de `pedido` antes de sus joins.
- `idx_tp4_detalle_pedido_cobertura (id_pedido) INCLUDE (id_producto, cantidad, precio_unitario)` cubre las lineas alcanzadas desde los pedidos filtrados.
- `idx_tp4_detalle_producto_pedido (id_producto, id_pedido) INCLUDE (cantidad, precio_unitario)` sigue Q3 desde el producto puntual hasta sus lineas. En la medicion real reemplazo un `Parallel Seq Scan` de detalle por un `Index Only Scan` y bajo de 65.141 ms a 0.460 ms (141.61x).

Que un indice exista no prueba una mejora. Si el optimizador conserva un `Hash Join`, o si el tiempo empeora, se documenta y se rechaza como mejora.

## Parte 2 - lectura critica

Usar `lectura_critica_plan.md` con Q3, que tiene los cuatro joins y una mejora real. Pegar el texto completo de ambos planes y la respuesta literal de la IA. Verificar que no confunda el `Parallel Seq Scan` anterior con el `Index Only Scan` posterior y que ningun costo estimado se informe como milisegundos.

## Parte 3 - equivalencia

`03_specs_equivalencia.sql` contiene dos specs cerradas:

1. Ranking de clientes por gasto: una version agrega primero y luego usa `RANK()`; la alternativa calcula el total con una subconsulta correlacionada.
2. Productos activos sin ventas en 90 dias: una version usa `NOT EXISTS` correlacionado y la alternativa usa `LEFT JOIN` con `HAVING`.

Se verifican ambos sentidos de `EXCEPT`; los cuatro controles deben devolver cero.

## Parte 4, DUIA y evidencia

`04_consulta_comun_competencia.sql` es una consulta analitica comun con cuatro tablas y agregacion. La tabla de `plantillas_evidencia.md` permite registrar el tiempo antes/despues y la estrategia efectivamente aceptada. `duia_tp4.md` es la declaracion de uso de IA: completar solo con prompts, planes y decisiones que realmente se hayan usado.
