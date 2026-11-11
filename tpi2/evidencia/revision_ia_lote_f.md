| Ruta | Revisado | Hallazgo prioritario |
|---|---|---|
| tp8/backup_foodstore.ps1 | sí | sin hallazgo prioritario (7 controles, L59) |
| tp8/build_informe_u6_pdf.py | sí | L20-22: EVIDENCE por max nombre sin validar directorio/manifiesto |
| tp8/health_check.sql | sí | sin hallazgo prioritario |
| tp8/maintenance.sql | sí | sin hallazgo prioritario |
| tp8/restore_test.ps1 | sí | L95-101: compara conteos; no valida datos inválidos del origen |
| tp8/validation.sql | sí | sin hallazgo prioritario |
| tp9/build_informe_tp9_pdf.py | sí | L89-93: depende de evidencias no generadas por scripts del lote |
| tp9/comparar_resultados.ps1 | sí | L2-3: rutas fijas a psql/mongosh dependientes del entorno |
| tp9/consultas_mongodb.js | sí | sin hallazgo prioritario |
| tp9/consultas_postgresql.sql | sí | sin hallazgo prioritario (requiere salida -At) |
| tp9/export_pedidos.sql | sí | sin hallazgo prioritario |
| tp9/migrar_mongodb.js | sí | L9: ruta de export relativa a process.cwd() |
| tp9/verificar_mongodb.js | sí | L60-62: asume error.code===121 para rechazo del validador |

Hallazgos accionables (máx 4):
1. Alta — tp9/build_informe_tp9_pdf.py:89-93 — build depende de evidencias no generadas por scripts del lote.
2. Media — tp9/verificar_mongodb.js:60-62 — rechazo por validador asumido como code 121.
3. Media — tp8/restore_test.ps1:95-101 — no verifica datos inválidos del origen antes del simulacro.
4. Baja — tp9/migrar_mongodb.js:9 y tp8/build_informe_u6_pdf.py:20-22 — dependencias de cwd y selección de evidencia por nombre.
