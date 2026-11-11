# Revisión OpenCode Plan · suplemento de seis scripts finales

Prompt: «Lee por completo `tpi2/qa_revision_paquetes/suplemento.txt` (452 líneas) con los seis scripts modificados o nuevos. No uses shell ni modifiques archivos. Devuelve una fila por cada ruta y hasta tres observaciones accionables; no inventes pruebas».

OpenCode 1.18.16, agente Plan, modelo `opencode/beam-free`, leyó el paquete y cada archivo por separado. Respuesta final:

| Ruta | Revisado | Hallazgo |
|---|---|---|
| `tp4/build_entrega_pdf.py` | Sí | Imports no usados (`escape`, `landscape`); anexos dependen de archivos de evidencia en ejecución. |
| `tp10/movil/schema_sqlite.sql` | Sí | Sin hallazgo prioritario: FK, STRICT y CHECK coherentes. |
| `tp10/movil/semaforo.sql` | Sí | Sin hallazgo prioritario: idempotencia y prioridad rojo > amarillo. |
| `tpi2/opencode_variantes/schema_sqlite.sql` | Sí | Sin hallazgo prioritario: igual al adoptado. |
| `tpi2/opencode_variantes/semaforo.sql` | Sí | Sin hallazgo prioritario: igual al adoptado. |
| `tpi2/probar_sqlite_opencode.py` | Sí | Prueba diferencial no ejecutada por la IA; requiere Git y el commit `b6cd291`. |

Decisiones de integración: los imports sobrantes son cosméticos; los dos planes anexos existen y se renderizó el PDF de TP4. El commit `b6cd291` existe y `probar_sqlite_opencode.py` se ejecutó con ocho solicitudes y tres errores esperados (`sqlite_opencode_equivalencia.txt`). Los dos SQL adoptados tienen los mismos hashes que las variantes guardadas. La respuesta de OpenCode fue de lectura; no se le atribuyen estas comprobaciones posteriores.
