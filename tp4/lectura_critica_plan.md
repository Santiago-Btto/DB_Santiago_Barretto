# TP4 - Parte 2: lectura critica de un plan de joins

## Plan elegido: Q3 ventas mensuales de `producto.id_producto = 100001`

Los planes completos estan conservados en `evidencia/20260915_producto/`. La medicion confirmada fue 65.141 ms antes, con `Parallel Seq Scan` sobre `detalle_pedido`, y 0.460 ms despues, con `Index Only Scan` mediante `idx_tp4_detalle_producto_pedido` (141.61x).

```text
[PENDIENTE: pegar el plan real medido]
```

## Prompt enviado a la IA

> Explica este plan de PostgreSQL nodo por nodo sin asumir datos que no aparecen. Para cada `Nested Loop`, identifica la entrada externa y la interna. Distingue costo estimado, filas estimadas, filas reales, bucles y `Execution Time`. No propongas cambios; solo interpreta el plan.

## Respuesta literal de la IA

```text
[PENDIENTE: pegar la respuesta completa y literal]
```

## Contraste con el plan real

| Afirmacion de la IA | Correcta | Correccion / evidencia del plan real |
|---|---|---|
| El indice permite buscar las lineas del producto 100001 sin recorrer todos los detalles. | Si, en el plan posterior | `Index Only Scan` sobre `idx_tp4_detalle_producto_pedido`; comparar con el `Parallel Seq Scan` anterior. |
| El costo estimado del nodo es el tiempo de ejecucion. | No | La evidencia temporal es `Execution Time`: 65.141 ms antes y 0.460 ms despues, no el campo `cost`. |
| [PENDIENTE: afirmacion literal de la IA sobre joins] | Si / No | Confirmar el nodo y sus `loops`/`rows` en el plan real antes de aceptarla. |

Conclusión a completar: aceptar solo una explicacion que coincida con la evidencia textual del plan y corregir cualquier imprecision antes de usarla en la defensa.
