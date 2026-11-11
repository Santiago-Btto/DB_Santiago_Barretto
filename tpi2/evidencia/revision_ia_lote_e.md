| Ruta | Revisado | Hallazgo (línea) / sin hallazgo prioritario |
|---|---|---|
| tp6/00_preparar_base_u4.sql | sí | sin hallazgo prioritario |
| tp6/build_informe_tp_u4_pdf.py | sí | sin hallazgo prioritario |
| tp6/run_tp_u4.ps1 | sí | sin hallazgo prioritario |
| tp6/tp_desnormalizacion_top_categorias.sql | sí | sin hallazgo prioritario |
| tp6/tp_fnbc_control_lote.sql | sí | sin hallazgo prioritario |
| tp7/00_preparar_base_u5.sql | sí | l.67-71: `fn_autenticar` registra `p_email` en `auditoria_evento.detalle` (PII en traza) |
| tp7/run_tp_u5.ps1 | sí | sin hallazgo prioritario |
| tp7/sql/auditoria_test.sql | sí | l.4-7: `ALTER SYSTEM` global afecta todo el servidor, no solo la base de lab |
| tp7/sql/restaurar_configuracion_auditoria.sql | sí | sin hallazgo prioritario |
| tp7/sql/roles.sql | sí | l.74-77: `admin_datos` puede `INSERT password_hash` directo (bypass de `crypt`) |
| tp7/sql/simulacro_incidente.sql | sí | sin hallazgo prioritario |
| tp7/sql/usuario_anon.sql | sí | l.18-23: anonimización basada en `id_usuario` → reidentificación trivial |
| tp7/sql/verificar_permisos.sql | sí | sin hallazgo prioritario |

**Hallazgos accionables (máx 4):**
1. `tp7/sql/auditoria_test.sql:4-7` — cambiar `ALTER SYSTEM` por configuración acotada/sesión para no tocar el servidor completo.
2. `tp7/sql/usuario_anon.sql:18-23` — pseudonimizar sin conservar `id_usuario` (hash/salt o supresión) para evitar linkability.
3. `tp7/00_preparar_base_u5.sql:67-71` — no persistir email en `detalle`; usar identificador hasheado/truncado.
4. `tp7/sql/roles.sql:74-77` — restringir `INSERT` de `password_hash` a función `SECURITY DEFINER` con `crypt()`, no columna directa.
