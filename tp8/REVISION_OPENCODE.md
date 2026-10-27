# Revisión de asistencia de OpenCode

El 27/10/2026 se invocó OpenCode 1.18.16, agente `plan`, modelo `opencode/beam-free`, con la instrucción de leer `SPEC_U6.md` y proponer en texto scripts de respaldo y restauración, sin editar archivos. La primera invocación con el modelo configurado (`gemini-3-pro-image-preview`) no devolvió respuesta y se interrumpió; la segunda sí produjo un borrador. Los archivos entregados se implementaron y probaron después de esa revisión.

| Propuesta del borrador | Revisión y decisión |
|---|---|
| Lista de tablas en plural (`categorias`, `productos`, etc.) | Se rechazó: las tablas reales son `categoria`, `cliente`, `producto`, `pedido` y `detalle_pedido`. |
| Comparar la restauración con los conteos de la base principal al final | Se corrigió: la consigna exige comparar con los conteos registrados **antes** de `pg_dump`; se guardan en un manifiesto JSON. |
| Calcular RPO con la hora de modificación del archivo | Se corrigió: se usa la hora de inicio del respaldo registrada en el manifiesto, de forma conservadora. |
| Preguntar al operador antes de crear la base de prueba | Se reemplazó por guardas verificables: el nombre de destino es fijo y el script se detiene si existe. Esto permite repetir el procedimiento en automatización sin una respuesta interactiva. |
| Comprobar sólo `cantidad` en `detalle_pedido` | Se corrigió: se comprueba también `precio_unitario < 0`. Para `producto` se usa `precio_lista`, nombre real del esquema. |
| Escribir un archivo SHA con el nombre derivado de la ruta completa | Se rechazó por su construcción de ruta errónea. El SHA-256 y tamaño se guardan en el manifiesto. |

La aceptación final depende de salidas reales de `psql`, `pg_dump`, `pg_restore` y las validaciones. No se atribuyen a OpenCode mediciones ni ejecuciones que no realizó.
