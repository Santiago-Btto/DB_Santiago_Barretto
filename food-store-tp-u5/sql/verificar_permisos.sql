-- Verificacion de la Parte A. Debe ejecutarse en food_store_tp_u5_seguridad.

SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('rol_app_lectura', 'rol_app_escritura', 'rol_soporte', 'rol_reportes', 'rol_auditoria', 'app_web', 'soporte_operador', 'admin_datos')
ORDER BY grantee, table_name, privilege_type;

SELECT grantee, table_name, column_name, privilege_type
FROM information_schema.column_privileges
WHERE table_schema = 'public'
  AND table_name = 'usuario'
  AND grantee IN ('rol_soporte', 'admin_datos')
ORDER BY grantee, column_name, privilege_type;

SELECT member.rolname AS miembro, grupo.rolname AS rol_otorgado
FROM pg_auth_members AS m
JOIN pg_roles AS grupo ON grupo.oid = m.roleid
JOIN pg_roles AS member ON member.oid = m.member
WHERE member.rolname IN ('app_web', 'soporte_operador', 'admin_datos')
ORDER BY miembro, rol_otorgado;
