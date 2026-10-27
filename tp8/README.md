# TP8 - Unidad 6: mantenimiento, respaldo y recuperación

Trabajo práctico de Food Store ejecutado en PostgreSQL 18.4 el 27/10/2026. Se creó `foodstore` como copia local de `food_store_tp5_base` (carga de 50.000 productos, 200.000 pedidos y 400.000 detalles). El simulacro restauró el respaldo en `foodstore_restore_test`; las bases de trabajos anteriores no se modificaron.

## Archivos y orden de ejecución

1. `SPEC_U6.md`: plan de frecuencias, éxito y seguridad (una página).
2. `health_check.sql`: tamaño, actividad de conexiones, estadísticas de tablas y consultas activas. Ejecutar conectado a `foodstore` en DBeaver o `psql`; aborta si se conecta a otra base.
3. `maintenance.sql`: muestra el estado previo de autovacuum y ANALYZE; ejecuta `ANALYZE` sólo si faltan estadísticas o se supera el umbral de modificaciones. La segunda ejecución de laboratorio no realizó acción manual y el script aborta en otra base.
4. `backup_foodstore.ps1`: guarda conteos previos, crea un `.dump` custom con fecha y hora, comprueba formato/tamaño/SHA-256, genera manifiesto y log. Devuelve error si falla cualquier paso.
5. `restore_test.ps1`: elige el último manifiesto exitoso, comprueba hash, rehúsa una base de destino existente, crea `foodstore_restore_test`, restaura y compara cinco conteos contra los del manifiesto. También verifica dos condiciones lógicas y mide RPO/RTO.
6. `validation.sql`: siete controles usados en las dos bases; puede ejecutarse también en DBeaver.
7. `REVISION_OPENCODE.md`: intervención real de OpenCode y correcciones humanas al borrador.
8. `evidencia/20261027_091130/`: manifiesto y salidas reales del servidor. `EVIDENCIA.md` explica las mediciones.
9. `informe_u6.pdf`: informe de una página exigido por la guía. `DB_Santiago_Barretto.pdf` es la misma entrega con el nombre del repositorio para la plataforma.

## Ejecución manual

En PowerShell, desde la raíz del repositorio:

```powershell
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -X -w -v ON_ERROR_STOP=1 -h localhost -p 5432 -U postgres -d foodstore -f tp8\health_check.sql
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -X -w -v ON_ERROR_STOP=1 -h localhost -p 5432 -U postgres -d foodstore -f tp8\maintenance.sql
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tp8\backup_foodstore.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tp8\restore_test.ps1
```

Los scripts aceptan `-PgBin`, `-DbHost`, `-DbPort` y `-DbUser`. No piden ni almacenan contraseñas; `-w` evita que una tarea programada quede esperando una respuesta. Si el servidor exige contraseña, configurarla fuera del repositorio mediante `.pgpass` antes de ejecutar. En este laboratorio local la conexión PostgreSQL ya estaba configurada para entrar sin contraseña; esa configuración no es apropiada para producción.

La primera preparación de `foodstore` se hizo con `createdb --template=food_store_tp5_base foodstore`, sólo cuando el destino no existía. Para otro equipo, crear primero una base `foodstore` con el esquema y datos Food Store, y comprobar que las cinco tablas tengan datos antes de iniciar el respaldo.

`restore_test.ps1` se detiene si `foodstore_restore_test` ya existe. El ensayo repetido requiere eliminar **sólo esa base descartable**, tras revisar que es la copia del TP. El respaldo binario queda local en `tp8/backups/` y no se versiona. Los logs completos de ejecución quedan localmente en `tp8/logs/`; se versionó únicamente la evidencia seleccionada. No se configuró una tarea automática del sistema: los scripts están listos para programarse y fueron probados manualmente, como pide la guía.

## Decisiones y límites

- `producto.precio_lista` sustituye al `producto.precio` de ejemplo en la consigna porque ése es el nombre del esquema real.
- RPO observado = edad del respaldo desde el inicio de `pg_dump` hasta el inicio del simulacro. Es una ventana potencial; no demuestra por sí sola pérdida de datos.
- RTO observado = tiempo desde inmediatamente antes de `createdb` hasta terminar las validaciones. El chequeo previo del hash no se cuenta dentro del RTO.
- `ANALYZE` se justificó por la ausencia de estadísticas en la copia recién creada. Se descartó `VACUUM FULL` como rutina. El estado de tuplas muertas quedó documentado sin intervenirlo.
