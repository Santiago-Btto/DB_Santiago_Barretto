# Evidencia observada - 27/10/2026 (America/Buenos_Aires)

PostgreSQL 18.4. Base `foodstore` de 150 MB; fuente local `food_store_tp5_base`. Salidas directas en `evidencia/20261027_091130/`.

| Control | Resultado observado | Fuente |
|---|---:|---|
| Inicio de respaldo | 09:11:35,496 -03:00 | `backup_manifest.json` |
| Fin de respaldo | 09:11:36,802 -03:00 | `backup_manifest.json` |
| Archivo custom | 6.420.169 bytes; SHA-256 verificado; `pg_restore --list` exitoso | `backup_run.log`, `backup_manifest.json` |
| RPO de laboratorio previsto / observado | <= 24 h / 64,871 s | `restore_run.log` |
| RTO de laboratorio previsto / observado | <= 600 s / 2,664 s | `restore_run.log` |
| `categoria` | 5 antes y después | `validation_source.txt`, `validation_restored.txt` |
| `cliente` | 20.000 antes y después | Ídem |
| `producto` | 50.000 antes y después | Ídem |
| `pedido` | 200.000 antes y después | Ídem |
| `detalle_pedido` | 400.000 antes y después | Ídem |
| Productos / detalles inválidos | 0 / 0 | Ídem |

El respaldo se obtuvo sobre una copia de laboratorio sin escrituras concurrentes observadas. El RPO de 64,871 s es la edad conservadora del respaldo al arrancar el simulacro; la diferencia de conteos entre origen y restauración fue cero. El cronómetro del RTO comenzó justo antes de crear `foodstore_restore_test` y terminó al completar las siete consultas de validación.

`health_check.txt` muestra tamaño, una conexión durante el muestreo, estadísticas de las tablas y la consulta activa del propio chequeo. `maintenance.txt` documenta que las cinco tablas carecían de `last_analyze`/`last_autoanalyze`, por lo que se ejecutó `ANALYZE` condicional. En `maintenance_second_run.txt` la decisión para las cinco fue “sin acción manual necesaria”. Los archivos `health_check_guarded.txt` y `maintenance_guarded.txt` acreditan la versión final con control de base; `guard_wrong_database.log` registra que el mantenimiento abortó con código 3 al apuntar a `postgres`. Tras el primer ANALYZE se estimaron 1.800 tuplas muertas en `detalle_pedido`; no se ejecutó `VACUUM FULL`.

Problemas reales detectados: la consulta literal de la guía falló con «no existe la columna precio»; el esquema usa `precio_lista`. Además, la primera prueba del script de restauración mostró acentos mal codificados por PowerShell 5.1; se ajustaron las cadenas del script y se repitió el ensayo. La primera base de prueba, creada por este TP, se eliminó para repetirlo y se conservó la segunda restauración exitosa. La guarda contra sobreescritura se probó ejecutando de nuevo el script con el destino existente: abortó con código 1 sin borrarlo (`guard_existing_db.log`).

Mejora siguiente: enviar cada respaldo diario a un segundo almacenamiento con retención y verificación de hash, y programar el simulacro semanal. Esto reduce el riesgo de que una falla del disco local inutilice simultáneamente base y copia.
