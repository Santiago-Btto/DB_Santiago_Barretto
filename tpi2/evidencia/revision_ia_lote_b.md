| ruta | revisado | hallazgo |
|---|---|---|
| tp3/00_preflight.sql | sí | sin hallazgo prioritario (valida tablas/categorías y formato de lote, líneas 21-35) |
| tp3/00_seed_catalogo_inicial.sql | sí | sin hallazgo prioritario (idempotente con WHERE NOT EXISTS, línea 16) |
| tp3/01_carga_masiva.sql | sí | sin hallazgo prioritario; emparejamiento de pedidos por fecha asume current_timestamp constante en la transacción (líneas 103-114) |
| tp3/02_consultas_candidatas.sql | sí | \gset deja tp3_categoria_objetivo vacío si no hay productos TP3 y la Q1 falla (líneas 22-29) |
| tp3/03_indices_aceptados.sql | sí | verificación por LIKE sobre pg_get_indexdef (líneas 24-35) |
| tp3/04_parte4_consultas.sql | sí | sin hallazgo prioritario (EXCEPT bidireccionales incluidos, líneas 32-47 y 83-107) |
| tp3/05_validacion.sql | sí | chequeo de email duplicado global, no acotado al lote (línea 43); sin hallazgo prioritario |
| tp3/06_consulta_comun_competencia.sql | sí | sin hallazgo prioritario |
| tp3/07_indice_competencia.sql | sí | verificación por LIKE sobre pg_get_indexdef (líneas 15-18) |
| tp3/build_anexos_pdf.py | sí | EVIDENCE hardcodeado (línea 20) y regex de conteo de filas (línea 30) |
| tp3/build_documento.py | sí | afirma tiempos/nodos sin verificación automática; sin hallazgo prioritario de código |
| tp3/dbeaver/00_preflight.sql | sí | SET app.tp3_lote hardcodeado a SB2026TP3 (línea 4) |
| tp3/dbeaver/00_seed_catalogo_inicial.sql | sí | sin hallazgo prioritario |
| tp3/dbeaver/01_carga_masiva.sql | sí | sin hallazgo prioritario (guardas de re-ejecución en líneas 17-27) |
| tp3/dbeaver/02_consultas_candidatas.sql | sí | Q1 usa CTE (líneas 10-29) en vez de \gset, cambiando el plan medido |
| tp3/dbeaver/03_indices_aceptados.sql | sí | sin hallazgo prioritario |
| tp3/dbeaver/04_parte4_consultas.sql | sí | sin hallazgo prioritario |
| tp3/dbeaver/05_validacion.sql | sí | sin hallazgo prioritario |
| tp3/dbeaver/06_consulta_comun_competencia.sql | sí | sin hallazgo prioritario |
| tp3/dbeaver/07_indice_competencia.sql | sí | sin hallazgo prioritario |
| tp3/run_mediciones.ps1 | sí | no ejecuta seed ni 06/07 de competencia (líneas 31-40) |

Hallazgos accionables:

1. **Alta** — `tp3/build_anexos_pdf.py:20,30`: `EVIDENCE` fijo a `evidencia/20260907_134508` y regex `^\(\d+ rows\)$` dependiente del locale de psql. Corrección: recibir el directorio como parámetro y parsear el cierre del plan de forma robusta (o forzar `LC_MESSAGES=C`).

2. **Media** — `tp3/run_mediciones.ps1:31-40`: no invoca `00_seed_catalogo_inicial.sql` ni los scripts 06/07 de competencia, por lo que la evidencia de Parte 5 no se recolecta y una BD creada solo con schema.sql falla en preflight. Corrección: agregar pasos condicionales para seed y medición antes/después del índice de competencia.

3. **Media** — `tp3/03_indices_aceptados.sql:24-35` y `tp3/07_indice_competencia.sql:15-18`: verificación por `LIKE` sobre `pg_get_indexdef`, sensible al formato (espacios/paréntesis) del motor. Corrección: validar vía `pg_index`/`indpred` o normalizar la definición.

4. **Baja** — `tp3/dbeaver/00_preflight.sql:4` y `tp3/dbeaver/02_consultas_candidatas.sql:10-29`: lote hardcodeado y Q1 con CTE que cambia el plan medido respecto a la variante psql (\gset). Corrección: parametrizar lote (ya documentado) y unificar la estrategia de obtención de categoría objetivo.
