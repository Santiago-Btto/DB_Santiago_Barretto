# 3.a - Mapa de la capa de datos

| Motor | Datos en este proyecto | Autoridad y flujo |
|---|---|---|
| PostgreSQL `foodstore` | Productos, precios, stock, clientes, pedidos y detalles. | Fuente autorizada. La prueba se ejecuta en la copia `foodstore_tp10_u8`; sólo ésta recibe cambios preparados para C2-C4. Publica una instantánea de cuatro productos. |
| MongoDB `foodstore_tp9.pedidos` | 20 pedidos y 40 líneas sintéticos de Unidad 7, con precios históricos y cliente esencial embebidos. | Copia documental de lectura y comparación; no decide stock ni recibe borradores. Se comprobó que existen 20 documentos y que el producto `100001` figura en ocho. |
| SQLite `foodstore_movil.db` | Caché del catálogo, instantánea recibida, borradores, ítems y cola de solicitudes con decisiones locales. | Fuente local sólo de borradores. `SIMULADO_APROBADO` es el resultado del ensayo, nunca una venta. Al volver la señal, el servidor real tendría que validar de nuevo y registrar una solicitud idempotente antes de crear pedido/descontar stock. |

Flujo: PostgreSQL → CSV `v_snapshot_movil` → SQLite. El MongoDB de TP9 se alimentó antes desde PostgreSQL para representar pedidos completos; no se sincroniza con la tablet en este laboratorio.
