# Food Store TP Unidad 5

Resolucion de administracion y seguridad sobre la copia aislada `food_store_tp_u5_seguridad`. Se partió de `food_store_tp5_base`, que conserva la carga poblada, y no se modificaron `practica_bd2`, `food_store_tp_u4_fnbc` ni las bases de entregas anteriores.

## Estructura solicitada

- `sql/roles.sql`: roles, GRANT, REVOKE, privilegio por columna y privilegios por defecto.
- `sql/auditoria_test.sql`: configuracion de auditoria nativa y operaciones de prueba.
- `sql/simulacro_incidente.sql`: cuatro intentos de autenticacion, lectura controlada y escalamiento bloqueado.
- `sql/usuario_anon.sql`: tabla anonimizada, dos consultas agregadas y equivalencia formal.
- `docs/kiro_roles_spec/`: requirements y design de permisos; registra transparentemente que Codex fue la herramienta disponible.
- `docs/`: informe de auditoria, fragmentos de log, respuesta de IA, informe de incidente y equivalencia.
- `BITACORA.md`: prompts, respuestas relevantes y validación humana de A a E.
- `evidencia/20261005_113300/du_roles.txt` y `verificacion_permisos.txt`: salida real de `\du` y de `information_schema`.

## Ejecucion en DBeaver

Conectarse a `food_store_tp_u5_seguridad` como `postgres` y ejecutar, en orden:

1. `00_preparar_base_u5.sql`
2. `sql/roles.sql`
3. `sql/auditoria_test.sql`
4. `sql/verificar_permisos.sql`
5. `sql/usuario_anon.sql`

El simulacro debe ejecutarse con la conexión `soporte_operador` y luego `sql/simulacro_incidente.sql`. Como los roles de login se definieron con `NOINHERIT`, el script realiza explícitamente `SET ROLE rol_soporte`.

## Seguridad de la copia

Los registros `usuario` son sintéticos. El archivo completo de log del servidor no se versiona: puede contener datos de otras sesiones. Solo se incluyen fragmentos seleccionados y anonimizado. El entorno local heredado usa `trust` en `pg_hba.conf`; esto permite practicar roles, pero no debe trasladarse a producción. `sql/restaurar_configuracion_auditoria.sql` revierte los parámetros de log al valor por defecto si ya no se desea conservar la auditoría del laboratorio.

## Resultados reales

- 1.203 usuarios de laboratorio, todos sintéticos.
- `app_web` no pudo seleccionar `email` de `usuario`.
- El simulacro obtuvo tres autenticaciones fallidas, una exitosa, leyó 1.000 filas permitidas y bloqueó el intento de obtener `admin_datos`.
- Las dos direcciones de equivalencia entre `usuario` y `usuario_anon` devolvieron 0 diferencias.

La evidencia de PostgreSQL está en `evidencia/20261005_113300/`.
