# DUIA - TP5: índices, vistas y vista materializada

## Registro de uso de IA y decisiones

| Herramienta | Propósito | Prompt o spec conservado | Resultado y decisión |
|---|---|---|---|
| OpenCode, sesión `ses_f31719b28ffeDr69oZrSEcV7Qg` | Leer las tres specs de índices sin editar archivos ni ejecutar SQL. | “Proponé sentencias `CREATE INDEX` precisas y un índice descartado por sobreindexación.” | OpenCode leyó las tres specs. La respuesta del proveedor terminó sin una propuesta final, por lo que no se aceptó SQL de forma ciega. La decisión final se basó en los planes medidos y está en `informe_mediciones.md`. |
| Codex / OpenAI | Preparar scripts PostgreSQL/DBeaver, revisar sintaxis y contrastar planes antes/después. | Specs de `specs/` y criterio: no aceptar si no cambia el plan o no mejora el tiempo real. | Se aceptaron tres índices tras ver `Bitmap Index Scan` o `Index Only Scan`; se rechazó el índice aislado sobre `producto.activo` por baja cardinalidad. |
| Codex / OpenAI | Definir vistas y comprobaciones formales. | `specs/04_vistas_reportes.md`: columnas, filtros y mínimo privilegio. | Cuatro vistas creadas. Los ocho controles de equivalencia con `EXCEPT` devolvieron 0. |
| Codex / OpenAI | Diseñar el reporte materializado y su refresco. | `specs/05_vista_materializada.md`: facturación mensual, `WITH DATA` e índice único. | Se aceptó la materializada: 550,464 ms para el reporte original frente a 0,067 ms en el resumen. |

## Registro requerido de Kiro

La consigna exige uso de Kiro para especificar antes de generar. Los cinco archivos de `specs/` contienen las especificaciones listas para esa interacción y no atribuyen a Kiro una sesión inexistente. Para completar el requisito literal de la cátedra, ejecutar en Kiro una revisión de esos archivos y agregar aquí la fecha, el prompt real y su respuesta antes de entregar.

El repositorio conserva el flujo completo y no declara como aceptada ninguna propuesta que no haya sido comprendida y medida en PostgreSQL.
