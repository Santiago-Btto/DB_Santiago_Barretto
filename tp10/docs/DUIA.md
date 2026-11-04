# Declaración de Uso de Inteligencia Artificial - Unidad 8

**Integrante:** Santiago Barretto. **Asignatura:** Bases de Datos II. **Trabajo:** TP8 de la cátedra, Unidad 8, Food Store en la feria.

Se utilizó **Codex** para redactar la spec, implementar scripts, ejecutar el laboratorio y producir la documentación. Se utilizó **OpenCode 1.18.16, agente Plan, modelo `opencode/beam-free`** para proponer el diseño inicial de SQLite y el semáforo, y para revisar scripts de distintas unidades. Las respuestas consultadas se preservan de forma acotada en `evidencia/opencode_diseno_respuesta.txt` y `evidencia/opencode_revision_respuesta.txt`; las decisiones se explican en `docs/bitacora_ia.md` y `docs/revision_opencode.md`.

La propuesta inicial se adaptó al esquema real `producto.precio_lista`, `stock`, `activo` y `deleted_at` de la copia PostgreSQL. Se agregaron campos obligatorios que la IA había omitido (`usuario`, `forma_pago`), se evitó una FK que impediría la independencia de la caché y se reforzó la prueba de no mutación del servidor. Se probaron C1-C7 en SQLite y PostgreSQL de laboratorio, incluidos dos errores de integridad esperados, UUID duplicado y ausencia de cambios causados por el semáforo. Se descartó con fundamento una observación de IA sobre el script de restauración de Unidad 6.

No se enviaron datos personales reales, contraseñas ni correos a las herramientas. Las conclusiones se basan en las salidas `evidencia/resultado_laboratorio.txt` y en el código versionado. La autoría y responsabilidad final del trabajo corresponden al estudiante.
