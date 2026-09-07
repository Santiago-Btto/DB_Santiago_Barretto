# Base de Datos II Food Store

Repositorio incremental del proyecto integrador Food Store para Base de Datos II. `schema.sql` es el punto de partida; cada trabajo practico agrega scripts, documentacion y evidencia sin borrar ni reemplazar los entregables anteriores.

## Estado general

La base y los scripts estan preparados para PostgreSQL. Ningun archivo afirma que un cambio fue aplicado ni que una medicion fue obtenida hasta que exista evidencia generada por el motor. Todos los trabajos se ejecutan sobre una copia de laboratorio, nunca sobre una base de produccion.

| Trabajo practico | Tema | Que incorpora al proyecto | Estado de evidencia |
|---|---|---|---|
| Base inicial | Modelo Food Store | `schema.sql`, tablas `cliente`, `categoria`, `producto`, `pedido` y `detalle_pedido`, claves, restricciones e indices iniciales. | Depende de la ejecucion local de `schema.sql`. |
| TP2 - Unidad 1 Semana 2 | Integridad, transacciones y concurrencia | Propuestas de restricciones de negocio, pruebas reversibles, laboratorio de dos sesiones, protocolo de seguridad, lectura critica y DUIA. | Scripts y documentos preparados. Las restricciones y escenarios deben verificarse en PostgreSQL real antes de afirmarlos como ejecutados. |
| TP3 - Unidad 2 Semana 3 | Optimizacion de consultas | Carga masiva de laboratorio, `ANALYZE`, tres consultas candidatas, indices bajo medicion, equivalencias con `EXCEPT`, competencia y DUIA. | Ejecutado en copias aisladas; evidencia real en `tp3/evidencia/20260907_134508/`. |

## Estructura

- `schema.sql`: esquema base del proyecto.
- `protocolo_seguridad.md`: copia, transaccion y respaldo antes de cualquier cambio.
- `sql/01_restricciones_integridad.sql`: restricciones propuestas por TP2.
- `sql/02_pruebas_restricciones.sql`: pruebas validas e invalidas de TP2 dentro de una transaccion reversible.
- `sql/03_laboratorio_concurrencia.sql`: guia de dos sesiones para TP2.
- `informe_concurrencia.md`, `ejercicio_lectura_critica.md`, `duia_parte_*.md`: documentacion y evidencias de TP2.
- `tp3/`: todos los scripts, documentacion, evidencia y el informe Word de TP3.

## Ejecucion segura

1. Leer `protocolo_seguridad.md` y crear una copia de trabajo de la base.
2. Crear un respaldo de la copia antes de cualquier cambio estructural.
3. Ejecutar los scripts de escritura primero dentro de `BEGIN ... ROLLBACK`; confirmar solo luego de revisar su efecto.
4. Conservar la salida real de `psql` y completar unicamente los campos de evidencia que esa salida demuestre.
5. Versionar cada TP y describir en su documentacion si modifica el esquema de forma permanente, si genera datos de laboratorio o si solo ejecuta consultas.

## TP2

El TP2 se ejecuta siguiendo el orden descripto en los documentos de raiz: protocolo, restricciones, pruebas reversibles, laboratorio de concurrencia en dos sesiones y actualizacion de los informes y DUIA con la evidencia real.

## TP3

La guia completa y los scripts estan en `tp3/README.md`. Sobre una copia `food_store_tp3_lab`, ejecutar desde `tp3/`:

```powershell
.\run_mediciones.ps1 -Database food_store_tp3_lab -Lote SB2026TP3 -PrepararDatos
```

El runner crea `tp3/evidencia/<fecha_hora>/` con la carga, los planes antes y despues, definiciones de indices y verificaciones de equivalencia. El informe Word `tp3/TP3_Entrega_Santiago_Barretto.docx` se completa con esa evidencia, sin inventar valores.

## Como agregar los proximos trabajos practicos

Crear una carpeta propia, por ejemplo `tp4/`, con un README que explique objetivo, prerrequisitos, orden de ejecucion, reversibilidad y evidencia requerida. Mantener scripts numerados; documentar que agrega cada uno y evitar editar o eliminar la evidencia de trabajos anteriores. Si el TP cambia el esquema, incluir una migracion, pruebas y un plan de respaldo; si solo mide o consulta, guardar la salida real junto al TP.
