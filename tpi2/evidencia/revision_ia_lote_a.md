| Ruta | Revisado | Hallazgo |
|---|---|---|
| schema.sql | sí | Sin hallazgo prioritario (email UNIQUE diferido a migración; falta índice en detalle_pedido.id_producto, menor) |
| sql/01_restricciones_integridad.sql | sí | L.21: `DROP CONSTRAINT IF EXISTS ck_producto_precio_no_negativo` asume estado previo no verificado; puede ocultar ausencia |
| sql/02_pruebas_restricciones.sql | sí | L.45-47: caso válido inserta detalle pero no se verifica persistencia (solo errores) |
| sql/03_laboratorio_concurrencia.sql | sí | L.131: `lock_timeout '10s'` inconsistente con el ejecutor PowerShell (5s) |
| tpi/01_migracion_modelo_final.sql | sí | L.61-62: `idx_tpi_producto_vigente_categoria` duplica `idx_producto_categoria_activo_vigente` (schema.sql L.77-80) |
| tpi/02_objetos_programables.sql | sí | L.34-36: trigger solo `UPDATE OF id_producto`; no valida vigencia en UPDATE de cantidad/precio ni cambios de estado |
| tpi/03_pruebas_objetos.sql | sí | Sin hallazgo prioritario (atomicidad y soft delete verificados dentro de ROLLBACK) |
| tpi/04_ejecutar_concurrencia.ps1 | sí | L.30-79: `LaboratorioId` interpolado en SQL sin parametrización; sin try/finally para limpieza |
| tpi/05_consultas_vigentes.sql | sí | Sin hallazgo prioritario |
| tpi/build_informe_tpi_pdf.py | sí | L.66: afirma "vista materializada" inexistente; L.92-96: métricas TP5 sin artefacto versionado en el lote |

**4 hallazgos accionables**

1. **Vista materializada fantasma en el informe** — `build_informe_tpi_pdf.py:66` (y métricas L.92-96). Severidad: media. Corrección: eliminar la mención o implementar la vista materializada y versionarla; las métricas TP5 deben referenciar archivos de evidencia existentes.
2. **Interpolación SQL no segura en PowerShell** — `04_ejecutar_concurrencia.ps1:30-79`. Severidad: media. Corrección: pasar `LaboratorioId` vía `psql -v` y validar formato (solo alfanumérico/guiones), o usar consultas parametrizadas.
3. **Índice duplicado producto/categoría** — `01_migracion_modelo_final.sql:61-62` vs `schema.sql:77-80`. Severidad: baja-media. Corrección: eliminar uno de los índices o renombrar para evitar costo de escritura duplicado.
4. **Inconsistencia de `lock_timeout`** — `03_laboratorio_concurrencia.sql:131` (10s) vs `04_ejecutar_concurrencia.ps1:75` (5s). Severidad: baja. Corrección: unificar el valor y documentarlo en el README.
