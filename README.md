# BDII - Laboratorio de concurrencia e IA

Entrega académica para PostgreSQL Food Store. No contiene ni afirma ejecuciones reales contra una base de datos.

## Indice de entrega

- `schema.sql`: esquema base provisto.
- `protocolo_seguridad.md`: creación segura de bases, respaldos y uso transaccional.
- `sql/01_restricciones_integridad.sql`: tres restricciones revisadas.
- `sql/02_pruebas_restricciones.sql`: pruebas válidas e inválidas reversibles.
- `sql/03_laboratorio_concurrencia.sql`: procedimientos para dos sesiones.
- `informe_concurrencia.md`: informe a completar con evidencia real.
- `ejercicio_lectura_critica.md`: análisis de dos patrones SQL riesgosos.
- `duia_parte_1.md`, `duia_parte_2.md`, `duia_parte_3.md`: declaraciones de uso de IA.

## Requisitos previos

- PostgreSQL con `psql`, `createdb`, `pg_dump` y `pg_restore` disponibles en `PATH`.
- Un rol con permisos para crear bases de laboratorio y objetos.
- Dos terminales independientes para la práctica de concurrencia.

## Orden recomendado

1. Leer y aplicar `protocolo_seguridad.md` para crear `food_store_tp2` desde `schema.sql`.
2. Respaldar la base en `backups\` antes de cambios estructurales.
3. Revisar las consultas iniciales de `sql/01_restricciones_integridad.sql`; abrir manualmente `BEGIN`, ejecutar el archivo y usar `COMMIT` solo si no hay violaciones. Para ensayo, usar `ROLLBACK`.
4. Ejecutar `sql/02_pruebas_restricciones.sql`; siempre termina con `ROLLBACK`.
5. Abrir dos sesiones `psql` y seguir exactamente `sql/03_laboratorio_concurrencia.sql`.
6. Ejecutar la limpieza final y comprobar que no queden filas `LAB_CONC_2026_%`.
7. Actualizar `informe_concurrencia.md` exclusivamente con evidencia capturada en las dos sesiones reales, reemplazando los campos **PENDIENTE DE EJECUCION**.
8. Completar los campos de comandos y resultados reales de los tres documentos `duia_parte_*.md`.
