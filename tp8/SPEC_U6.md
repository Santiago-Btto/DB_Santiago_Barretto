# SPEC_U6 - Mantenimiento y recuperación de Food Store

## Alcance y entorno

PostgreSQL 16 o superior, laboratorio local. La base principal se llama `foodstore` y se obtiene como copia de la carga existente `food_store_tp5_base`. El ensayo se restaura exclusivamente en la base nueva `foodstore_restore_test`. Los scripts de respaldo y restauración no borran ni reemplazan `foodstore` ni modifican sus datos; `maintenance.sql` sólo actualiza estadísticas con `ANALYZE` cuando corresponde. Si la base de prueba ya existe, el ensayo se detiene. Nunca guardar contraseñas en scripts, logs, evidencias o Git. Para una tarea programada, configurar autenticación externa al script (por ejemplo, `.pgpass`).

## Plan y criterio de éxito

| Tarea | Frecuencia propuesta | Éxito verificable |
|---|---|---|
| Respaldo custom con `pg_dump` | Diaria | Archivo `.dump` con fecha y hora, tamaño mayor que cero, listado legible con `pg_restore --list`, log con código de salida cero y SHA-256. |
| Chequeo de salud | Diaria | `health_check.sql` devuelve tamaño, conexiones, estado de tablas y consultas activas, sin errores. |
| Revisión de mantenimiento | Semanal | Estado de autovacuum/ANALYZE y tuplas muertas registrado; `ANALYZE` manual sólo cuando falten estadísticas o haya suficientes modificaciones, y se documenta el motivo. Nunca `VACUUM FULL` periódico. |
| Restauración de prueba | Semanal | Crear `foodstore_restore_test` a partir del último respaldo; comparar exactamente los cinco conteos previos, comprobar cero productos/detalles inválidos y registrar tiempos. |

## Medición y seguridad

El RTO observado empieza inmediatamente antes de crear la base de prueba y termina al pasar todas las validaciones. El RPO observado se expresa como edad del respaldo al iniciar el ensayo; no demuestra pérdida real de transacciones si no hubo cambios posteriores. Meta de laboratorio: RPO menor o igual a 24 horas y RTO menor o igual a 10 minutos. La creación de un respaldo nuevo exige una ejecución manual exitosa antes de programarlo. Se conserva sólo evidencia textual y el informe en Git; el archivo `.dump` queda ignorado.

## Revisión de asistencia

OpenCode puede proponer borradores a partir de esta especificación. Cada comando se revisa contra el esquema real y se prueba manualmente antes de aceptarse. Las diferencias con los ejemplos de la guía deben explicarse; en este esquema el precio del producto se llama `precio_lista`.
