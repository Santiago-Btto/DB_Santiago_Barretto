# Generación real de SQL SQLite con OpenCode Build

**Fecha:** 11/11/2026. **Herramienta:** OpenCode 1.18.16, agente Build, modelo `opencode/beam-free`.

**Prompt:** «Lee `tp10/docs/kiro/requirements.md`, `design.md`, `tasks.md` y los SQL existentes. Crea sólo `tpi2/opencode_variantes/schema_sqlite.sql` y `semaforo.sql`. Preserva tablas y columnas de `tp10/run_lab.py`, restricciones STRICT/FK/CHECK, prioridad RECHAZADO > CONFLICTO > SIMULADO_APROBADO y procesamiento sólo de PENDIENTE, sin escritura PostgreSQL. No modifiques originales ni ejecutes pruebas. Explica diferencias; presenta los archivos como candidatos para revisión».

**Acción observada en la sesión:** OpenCode ejecutó `Set-Content -Path "tpi2\opencode_variantes\schema_sqlite.sql"` y `Set-Content -Path "tpi2\opencode_variantes\semaforo.sql"`. Su respuesta final indicó que preservó las tablas/columnas, la lógica del semáforo y propuso dos índices nuevos: `idx_item_borrador_id_local` e `idx_cola_sync_id_local`. Declaró expresamente que el candidato no estaba probado.

**Contraste de Codex:** se descartó `idx_item_borrador_id_local` por redundante con la PK `(id_local, producto_id)`; se aceptó `idx_cola_sync_id_local` para la FK. Se quitó el BOM UTF-8 introducido por PowerShell y se restauró la explicación de la independencia de la caché. Los dos SQL corregidos se adoptaron en `tp10/movil/` y tienen contenido idéntico a las variantes conservadas aquí. La prueba diferencial contra el commit anterior `b6cd291` pasó con ocho solicitudes, tres errores de integridad y segunda corrida sin cambios (`sqlite_opencode_equivalencia.txt`). La base SQLite versionada recibió sólo el índice aceptado y conservó el hash de filas (`sqlite_db_indice_sin_cambio.txt`).

La spec fue escrita con Codex, conforme a la sustitución solicitada por el estudiante. No se atribuye uso de Kiro ni pruebas automáticas a OpenCode Build.
