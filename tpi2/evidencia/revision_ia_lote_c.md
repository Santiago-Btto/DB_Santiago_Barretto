| Ruta | Revisado | Hallazgo |
|---|---|---|
| tp4/00_preflight.sql | sí | sin hallazgo prioritario (SQL válido; evidencia muestra `categoria` con reltuples=-1, línea 8) |
| tp4/01_consultas_analiticas.sql | sí | Q2 `WHERE` sin indentar vs DBeaver (cosmético, líneas 47-48); SQL funcionalmente idéntico |
| tp4/02_indices.sql | sí | crea los 3 índices incluidos los 2 rechazados (documentado); `ANALYZE` sin `VACUUM` → Heap Fetches: 8 en Q3 |
| tp4/03_specs_equivalencia.sql | sí | sin hallazgo prioritario (4 EXCEPT devolvieron 0 en evidencia) |
| tp4/04_consulta_comun_competencia.sql | sí | sin hallazgo prioritario (idéntico a Q3) |
| tp4/05_validacion.sql | sí | evidencia `05_validacion.txt` lista solo 2/3 índices (falta `idx_tp4_detalle_producto_pedido`) |
| tp4/build_entrega_pdf.py | sí | línea 53: DB "food_store_tp4_evidencia" vs real "food_store_tp4_analitica" (preflight línea 3) |
| tp4/dbeaver/00_preflight.sql | sí | sin hallazgo prioritario (metacomandos omitidos correctamente) |
| tp4/dbeaver/01_consultas_analiticas.sql | sí | sin hallazgo prioritario |
| tp4/dbeaver/02_indices.sql | sí | sin hallazgo prioritario |
| tp4/dbeaver/03_specs_equivalencia.sql | sí | sin hallazgo prioritario (SHA256 idéntico al CLI) |
| tp4/dbeaver/04_consulta_comun_competencia.sql | sí | sin hallazgo prioritario (solo difiere encabezado) |
| tp4/dbeaver/05_validacion.sql | sí | sin hallazgo prioritario (SHA256 idéntico al CLI) |

Hallazgos accionables (máx. 4):

1. **HIGH** — `build_entrega_pdf.py:53` nombra la copia "food_store_tp4_evidencia", pero `evidencia/.../00_preflight.txt:3` reporta "food_store_tp4_analitica". Corrección: corregir el string y regenerar el PDF.
2. **MEDIUM** — `evidencia/20260915_205300/05_validacion.txt` muestra 2/3 índices; falta `idx_tp4_detalle_producto_pedido`, aunque `q_producto_despues.txt` lo usa (Index Only Scan). Corrección: recapturar validación sobre la copia con los 3 índices o documentar la línea temporal antes de entregar.
3. **MEDIUM** — `q_producto_despues.txt:16` muestra `Heap Fetches: 8` en el Index Only Scan; `02_indices.sql` solo hace `ANALYZE`, no `VACUUM`, por lo que el acceso no es totalmente index-only. Corrección: añadir `VACUUM (ANALYZE) detalle_pedido;` antes de medir o documentar `Heap Fetches: 8` en plantillas/README.
4. **LOW** — `00_preflight.txt:8` muestra `categoria` con `reltuples=-1` (sin estadísticas en la copia origen). Corrección: asegurar que `ANALYZE categoria` (ya en `02_indices.sql`) se ejecute y recapturar preflight con stats, o anotar el estado inicial.
