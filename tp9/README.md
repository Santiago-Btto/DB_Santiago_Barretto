# TP9 - Unidad 7: NoSQL y Food Store

Resolución en la rama `codex/tp9-unidad7-nosql`. Se ejecutó sobre PostgreSQL 18.4 (`foodstore`) y MongoDB Community 9.0.4 (`foodstore_tp9.pedidos`) el 02/11/2026. Se migraron 20 pedidos y 40 líneas de la carga sintética existente; no se alteró la base relacional ni se migró el proyecto completo.

## Entregables

- `MODELO_DOCUMENTAL.md`: tablas y claves, campos, embebidos, reglas de integridad y tratamiento honesto del estado ausente.
- `export_pedidos.sql`: genera 20 documentos Extended JSON desde PostgreSQL.
- `data/pedidos_export.ndjson`: exportación real, reproducible, sin email ni teléfono; identificadores, fecha original y precios históricos preservados.
- `migrar_mongodb.js`: crea base y colección nuevas, valida la aritmética y los campos, inserta documentos e índices. Se detiene si la colección ya existe.
- `consultas_mongodb.js` y `consultas_postgresql.sql`: las cuatro consultas de la guía y una quinta por la forma de pago real.
- `comparar_resultados.ps1`: compara automáticamente cantidad e IDs entre motores para estado, producto, total y forma de pago.
- `verificar_mongodb.js`: comprueba 20 documentos y 40 líneas contra la exportación campo a campo; prueba que MongoDB rechaza una línea con cantidad cero.
- `IA_CONTRASTE.md`: prompt real, dos afirmaciones contrastadas con documentación oficial y conclusión de menos de 200 palabras.
- `evidencia/20261102_133900/`: salidas de los dos motores, comparación y comprobaciones.
- `DB_Santiago_Barretto.pdf`: informe de entrega, de hasta cinco páginas y sólo sobre este TP.

## Ejecución reproducible en Windows

Se requiere PostgreSQL con la base `foodstore`, MongoDB local en `127.0.0.1:27017`, `psql` y `mongosh`. En este equipo el servidor MongoDB se instaló por `winget` y está limitado a localhost; no se configuró un clúster ni se publicaron credenciales. Ejecutar desde la raíz del repositorio:

```powershell
$pg = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
$mongo = "$env:LOCALAPPDATA\Programs\mongosh\mongosh.exe"
$rows = & $pg -X -w -v ON_ERROR_STOP=1 -At -h localhost -p 5432 -U postgres -d foodstore -f tp9\export_pedidos.sql
if ($LASTEXITCODE -ne 0) { throw 'Falló la exportación' }
$rows | Set-Content -LiteralPath tp9\data\pedidos_export.ndjson -Encoding UTF8
& $mongo 'mongodb://127.0.0.1:27017/admin' --quiet --file tp9\migrar_mongodb.js
& $mongo 'mongodb://127.0.0.1:27017/admin' --quiet --file tp9\consultas_mongodb.js
& $mongo 'mongodb://127.0.0.1:27017/admin' --quiet --file tp9\verificar_mongodb.js
& $pg -X -w -v ON_ERROR_STOP=1 -At -F '|' -h localhost -p 5432 -U postgres -d foodstore -f tp9\consultas_postgresql.sql
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tp9\comparar_resultados.ps1
```

`migrar_mongodb.js` evita sobrescribir una colección existente. Para reproducir la migración en otro entorno, usar una instancia MongoDB nueva o revisar explícitamente la colección de laboratorio antes de eliminarla. Los scripts de consultas pueden abrirse también en DBeaver: `consultas_postgresql.sql` conectado a `foodstore` y `consultas_mongodb.js` en `mongosh`.

## Resultado observado

| Consulta | PostgreSQL | MongoDB | IDs idénticos |
|---|---:|---:|---|
| Estado `sin_estado_en_origen` | 20 | 20 | Sí |
| Producto `100001` en líneas | 8 | 8 | Sí |
| Total histórico > 10.000,00 | 6 | 6 | Sí |
| Forma de pago `TARJETA` (adicional) | 7 | 7 | Sí |

El umbral 10.000,00 separa seis de los veinte pedidos observados (totales de la muestra entre 3.418,00 y 26.099,00). `pedido` no tiene columna `estado`, por lo que el filtro de estado es una marca de ausencia compartida por ambas consultas, no una condición de negocio real. La consulta adicional sobre `forma_pago` demuestra un filtro selectivo con un dato auténtico. No se atribuye a esta muestra ninguna comparación de rendimiento.
