# Informe de auditoria

La auditoria se activo en el servidor local de desarrollo con `log_connections = on`, `log_disconnections = on` y `log_statement = all`. Se fijo un prefijo de linea que agrega fecha, PID, usuario, base, aplicacion y cliente remoto. La configuracion se aplico con `ALTER SYSTEM` seguido de `pg_reload_conf()` y esta limitada al entorno local.

La prueba registra una lectura, una insercion y una actualizacion reversibles; ademas, el runner abre una conexion con un rol inexistente para producir un evento FATAL de inicio de sesion fallido sin cambiar `pg_hba.conf` ni probar contrasenas ajenas. El fragmento resultante se conserva en `log_auditoria_prueba.txt`.

Los campos utiles para auditoria son quien ejecuta la operacion (`user`), que base y aplicacion intervienen, cuando ocurre el evento, el origen de red y la sentencia registrada. El log nativo no reemplaza una auditoria a nivel de fila: no ofrece por si mismo una historia semantica completa de valores antes y despues. Una solucion como pgaudit ampliaria el detalle segun la politica definida por el administrador.

El archivo de log es un activo sensible porque puede contener usuarios, sentencias, identificadores y datos de operacion. Debe poder leerlo solamente el administrador del servicio PostgreSQL y, cuando corresponda, un rol de auditoria autorizado; a nivel de sistema operativo se debe restringir la carpeta de logs al usuario que ejecuta PostgreSQL y administradores autorizados.
