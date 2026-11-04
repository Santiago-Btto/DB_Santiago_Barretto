# Tareas de implementación y verificación

1. Preparar una copia PostgreSQL de Food Store y la vista `v_snapshot_movil`; registrar los conteos iniciales y la selección sintética.
2. Crear `schema_sqlite.sql` con `PRAGMA foreign_keys = ON`, tablas `STRICT`, validaciones y tablas auxiliares de instantánea.
3. Crear `pruebas_sqlite.sql` y ejecutar COMMIT, ROLLBACK, C1 y C7 con errores observables y sin filas parciales.
4. Crear `semaforo.sql` para procesar sólo `PENDIENTE` con prioridad rojo > amarillo > verde; comprobar C2 a C6 y las nuevas instantáneas CSV.
5. Verificar que PostgreSQL no registra pedidos nuevos ni descuentos de stock durante la simulación; documentar qué cambios sí se prepararon explícitamente en la copia.
6. Integrar mapa PostgreSQL/MongoDB/SQLite, plan de mantenimiento de Unidad 6, revisión real de OpenCode, bitácora, DUIA, informe de hasta seis páginas y guía reproducible.

La revisión de IA debe dejar al menos tres hallazgos de dos unidades distintas y uno descartado con fundamento.
