# TP Unidad 4 - FNBC y desnormalizacion controlada

Resolucion del trabajo practico de la Unidad 4 para Food Store. El TP no modifica `practica_bd2` ni las copias usadas en entregas anteriores: se ejecuta sobre la copia aislada `food_store_tp_u4_fnbc`, creada desde la carga masiva `food_store_tp5_base`.

## Entregables

- `tp_fnbc_control_lote.sql`: Parte 1 completa. Crea el esquema original, la instancia dada, las tablas descompuestas, la vista de compatibilidad, la migracion y las verificaciones con `EXCEPT`.
- `tp_desnormalizacion_top_categorias.sql`: Parte 2 completa. Crea la vista materializada, los triggers de sincronizacion, ambos `EXPLAIN ANALYZE`, la auditoria y una prueba reversible del mecanismo.
- `Informe_TP_U4_FNBC_Desnormalizacion.pdf`: informe final con dependencias, claves, FNBC, justificacion de la descomposicion, planes antes/despues y decision de desnormalizacion.

## Base usada y evidencia real

La ejecucion se realizo el 03/10/2026 con PostgreSQL 18.4 sobre `food_store_tp_u4_fnbc`:

| Control | Resultado |
|---|---:|
| Productos de la copia de origen | 50.000 |
| Pedidos de la copia de origen | 200.000 |
| Detalles de la copia de origen | 400.000 |
| Pedidos en `CURRENT_DATE` luego de preparar la copia | 311 |
| Detalles en `CURRENT_DATE` luego de preparar la copia | 622 |
| Consulta normalizada | 49,870 ms |
| Consulta sobre la materializada | 0,344 ms |
| Diferencias de auditoria | 0 |

La salida directa del motor esta en `evidencia/20261003_153429/`. Los valores del informe se toman de esos archivos, no de estimaciones.

## Ejecucion reproducible en DBeaver

1. Conectarse como `postgres` a `food_store_tp_u4_fnbc` (la copia creada para este TP).
2. Ejecutar en este orden `00_preparar_base_u4.sql`, `tp_fnbc_control_lote.sql` y `tp_desnormalizacion_top_categorias.sql`.
3. Guardar las salidas de DBeaver. Las verificaciones de equivalencia y la auditoria deben mostrar cero filas o cero diferencias.
4. No ejecutar los scripts sobre `practica_bd2`, ni sobre las bases de TP3, TP4, TP5 o TPI.

El archivo `00_preparar_base_u4.sql` agrega en la copia los campos `eliminado` y `subtotal` que utiliza literalmente la consulta de la consigna. Tambien mueve las fechas solo dentro de la copia para que `CURRENT_DATE` tenga ventas y el plan medido sea significativo.

## Ejecucion automatizada opcional

Si todavia no existe la copia, desde PowerShell:

```powershell
cd 'C:\Users\esteb\Desktop\faku\3r Semestre\BDII\U1\DB_Santiago_Barretto\tp6'
.\run_tp_u4.ps1
```

El runner crea una copia desde `food_store_tp5_base`, nunca borra una base existente y guarda una nueva carpeta de evidencia. Si PostgreSQL estuviera instalado en otra ruta, indicar `-PsqlPath 'C:\ruta\a\psql.exe'`.

## Decisiones tecnicas

En la Parte 1 las dependencias son `{LoteID, DepositoID} -> ResponsableControlID` y `ResponsableControlID -> DepositoID`. Esta ultima viola FNBC porque el responsable no determina el lote. La descomposicion es `responsable_deposito(ResponsableControlID, DepositoID)` y `control_lote_responsable(LoteID, ResponsableControlID)`; el atributo comun es clave de la primera relacion, por lo que la reunion natural es sin perdida.

En la Parte 2 se eligio una vista materializada diaria por categoria. Se refresca con triggers `AFTER ... FOR EACH STATEMENT` sobre las cuatro tablas que alimentan el reporte. El `REFRESH MATERIALIZED VIEW` ocurre dentro de la misma transaccion que el cambio fuente: ante `ROLLBACK`, tambien se revierte el refresh. Por lo tanto la estructura es sustituible, auditable y reversible sin perder informacion de las tablas fuente.
