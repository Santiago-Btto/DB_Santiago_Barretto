# TP8 de la cátedra - Unidad 8: Food Store en la feria

En este repositorio el trabajo está en `tp10/` porque `tp8/` corresponde a Unidad 6 y `tp9/` a Unidad 7. La rama de desarrollo es `codex/tp10-unidad8-sqlite`. La rama `main` sólo enlaza esta entrega desde su README. El laboratorio usa la base PostgreSQL `foodstore` de TP9 como fuente, crea la copia `foodstore_tp10_u8`, reutiliza la colección MongoDB de TP9 para el mapa de datos y crea la tablet SQLite `movil/foodstore_movil.db`. No se registra ninguna venta desde la tablet.

## Archivos y orden

1. `docs/kiro/requirements.md`, `design.md`, `tasks.md`: spec EARS escrita antes de implementar. OpenCode Plan produjo propuestas a partir de esas tareas; sus respuestas revisadas están en `evidencia/`.
2. `servidor_snapshot.sql`: guardia de base, lápida sólo en la copia, vista PostgreSQL `v_snapshot_movil` de cuatro productos sintéticos (incluido el `100001` de TP9).
3. `movil/schema_sqlite.sql`: comienza con `PRAGMA foreign_keys = ON;` y crea cinco tablas `STRICT` (las cuatro pedidas y `snapshot_servidor`) con centavos enteros, FKs y `CHECK`.
4. `movil/pruebas_sqlite.sql`: COMMIT, ROLLBACK, catálogo offline C1 y los dos errores esperados C7.
5. `movil/semaforo.sql`: decide sólo solicitudes `PENDIENTE`; prioridad `RECHAZADO > CONFLICTO > SIMULADO_APROBADO` y motivo. Sólo escribe en SQLite.
6. `run_lab.py`: orquesta la exportación PostgreSQL a CSV, importación SQLite y C1-C7 con comprobaciones automáticas antes/después. No sobrescribe una base existente.
7. `movil/servidor_snapshot.csv` y `movil/foodstore_movil.db`: instantánea final con lápida y base local ejecutada; `evidencia/snapshots/` conserva cada etapa.
8. `docs/`: selección de datos, mapa de tres motores, mantenimiento, revisión OpenCode, bitácora, DUIA, spec y guion de defensa. `docs/informe.pdf` y `DB_Santiago_Barretto.pdf` son el mismo informe de entrega de hasta seis páginas.

## Crear y ejecutar desde cero

**Precondición:** PostgreSQL 16+ en localhost:5432 con una base `foodstore` de laboratorio procedente de la carga sintética de TP3 usada en [TP9](../tp9/README.md): 50.000 productos, 200.000 pedidos y 400.000 detalles. Si se parte sólo de `schema.sql`, seguir primero el orden de [TP3](../tp3/README.md) para crear la carga. El runner se detiene si estos conteos no coinciden, si faltan los IDs `100001` a `100004`, si la copia ya se usó o si el archivo SQLite ya existe. Se requieren `psql.exe` y `createdb.exe` en `C:\Program Files\PostgreSQL\18\bin`, Python 3.12+ con SQLite 3.37+ y permisos locales de PostgreSQL ya configurados. No se guardan contraseñas.

Desde la raíz del repositorio, con una copia PostgreSQL y salida SQLite **nuevas**:

```powershell
python tp10\run_lab.py
```

El script crea `foodstore_tp10_u8` mediante `TEMPLATE foodstore`, prepara únicamente cuatro productos en esa copia para C2-C4, exporta CSV con `\copy` a partir de `v_snapshot_movil`, importa la instantánea y ejecuta el semáforo. Si se creó manualmente una copia fresca con ese nombre antes de correrlo, usar `python tp10\run_lab.py --existing-fresh-lab` siempre que `movil/foodstore_movil.db` no exista. Para repetir el ensayo, conservar primero la evidencia deseada y preparar **otra copia fresca**: el runner no borra la copia ni el archivo SQLite por cuenta propia. En un checkout del repositorio ya viene la base SQLite entregada; mover ese archivo fuera de `tp10/movil/` antes de una reproducción nueva.

Comprobaciones de solo lectura sobre los artefactos entregados:

```powershell
sqlite3 tp10\movil\foodstore_movil.db "PRAGMA foreign_keys=ON; SELECT estado,count(*) FROM cola_sync GROUP BY estado; PRAGMA integrity_check; PRAGMA foreign_key_check;"
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -X -w -At -h localhost -p 5432 -U postgres -d foodstore_tp10_u8 -c "SELECT id,precio_centavos,stock_visto,disponible,eliminado FROM v_snapshot_movil ORDER BY id;"
```

## Resultados observados el 04/11/2026

| Caso | Resultado real |
|---|---|
| C1 | Cuatro productos consultados offline; borrador+ítem+solicitud guardados con COMMIT; ROLLBACK sin fila residual. |
| C2 | Cambio de precio de 100001: `CONFLICTO`; nuevo UUID tras aceptar precio: `SIMULADO_APROBADO`. |
| C3 | Stock de 100002 bajado a 2 mientras se solicitan 5; también cambió el precio: `RECHAZADO`, prevalece rojo. |
| C4 | Baja lógica de 100003: `RECHAZADO`; desaparece del catálogo disponible, permanece la lápida. |
| C5 | Sin cambios en 100004: `SIMULADO_APROBADO`. |
| C6 | UUID duplicado: error de clave primaria; segunda corrida del semáforo: cero cambios. |
| C7 | Cantidad 0: `CHECK` rechazado; producto 999999: FK rechazada; cero ítems nuevos. |

En cada corrida del semáforo se compararon cantidad de pedidos, suma de stock y hash de precio/stock/actividad/lápida de los cuatro productos PostgreSQL antes/después; coincidieron. Los cambios de servidor entre casos fueron preparación explícita en `foodstore_tp10_u8`. La base original `foodstore` conservó sus conteos y los cuatro productos. La cola final tiene un `CONFLICTO`, dos `RECHAZADO` y tres `SIMULADO_APROBADO`; ninguno es una venta.

## Entrega y límites

La guía pide un `.zip` o enlace al repositorio con la etiqueta `tp8`; la etiqueta de este TP apunta a la rama nueva. Para la plataforma, el informe con nombre del repositorio es `DB_Santiago_Barretto.pdf`; los scripts, CSV, base SQLite, spec y evidencia están en la rama. `docs/ensayo_defensa.md` prepara el guion de 10 minutos; la defensa ante la cátedra debe realizarla el estudiante. Los archivos `docs/kiro/` tienen el formato solicitado, pero no se afirma haber abierto la aplicación Kiro: la redacción se hizo con Codex y la propuesta/revisión con OpenCode Plan, declarados en la DUIA.
