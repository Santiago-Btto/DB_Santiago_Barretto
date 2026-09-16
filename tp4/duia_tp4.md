# DUIA - TP4: reportes analiticos y optimizacion de joins

## Declaracion transparente

Herramienta de asistencia: Codex / OpenAI. Se utilizo para proponer consultas, indices candidatos, specs y controles de equivalencia. La aceptacion depende de comprender cada sentencia, medirla en una copia y contrastarla contra el plan real. No se declaran aqui mejoras, algoritmos ni tiempos que aun no hayan sido medidos.

| Herramienta | Para que se uso | Prompt / spec (resumen) | Se acepto / descarto y por que |
|---|---|---|---|
| Codex / OpenAI | Parte 1 | Proponer dos consultas analiticas Food Store con al menos tres joins, agregacion y ventana, usando solo el esquema entregado. | SQL preparado; pendiente de validar los planes reales antes/despues. |
| Codex / OpenAI | Indices | Proponer indices para filtrar `pedido` por fecha y cubrir el join desde pedido hacia detalle. | Candidatos creados como hipotesis; completar decision con evidencia real. |
| Codex / OpenAI | Q3 e indice puntual | Proponer un indice para ventas mensuales de `id_producto = 100001`, revisando el acceso a `detalle_pedido`. | Aceptado tras medir: `idx_tp4_detalle_producto_pedido` paso de Parallel Seq Scan a Index Only Scan y de 65.141 ms a 0.460 ms (141.61x). |
| Codex / OpenAI | Parte 2 | Explicar un plan real nodo por nodo, distinguiendo costo estimado y tiempo real. | Pendiente de pegar plan y contraste de la ejecucion real. |
| Codex / OpenAI | Parte 3 | Generar una version alternativa de un ranking y de una subconsulta correlacionada, con `EXCEPT` bidireccional. | Aceptar solo si los cuatro controles devuelven 0. |
| Codex / OpenAI | Competencia | Proponer una estrategia basada en el plan comun medido. | Pendiente: registrar tanto propuestas descartadas como la decision final. |

## Registro de decisiones despues de medir

| Fecha | Consulta | Propuesta de IA | Evidencia real revisada | Decision y motivo |
|---|---|---|---|---|
| PENDIENTE | Q1 | PENDIENTE | PENDIENTE | PENDIENTE |
| PENDIENTE | Q2 | PENDIENTE | PENDIENTE | PENDIENTE |
| 2026-09-15 | Q3 ventas mensuales de producto 100001 | `idx_tp4_detalle_producto_pedido` con cobertura de cantidad y precio | Parallel Seq Scan de detalle: 65.141 ms; Index Only Scan: 0.460 ms | Aceptado: 141.61x de mejora real, con el mismo reporte y filtro. |
| PENDIENTE | Competencia | PENDIENTE | PENDIENTE | PENDIENTE |
