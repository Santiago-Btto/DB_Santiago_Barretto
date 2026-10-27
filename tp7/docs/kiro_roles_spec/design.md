# Design de roles Food Store

La implementacion separa roles de grupo sin inicio de sesion de identidades con inicio de sesion. Los roles de grupo reciben privilegios de objeto; las identidades solo heredan el grupo que necesitan. `NOINHERIT` obliga a que las membresias se otorguen de forma explicita y evita que un rol de grupo se use como identidad de conexion.

La tabla `usuario` contiene datos personales y hashes de prueba, por lo que no se concede `SELECT` general. Soporte recibe privilegios por columna y accede a las funciones `SECURITY DEFINER` con `search_path` fijo. La vista de reportes encapsula el agregado que puede consumir `rol_reportes`.

La politica futura se implementa con `ALTER DEFAULT PRIVILEGES`: se revoca toda exposicion a `PUBLIC`, en vez de otorgar permisos amplios a roles de aplicacion sobre objetos aun no analizados. Esto conserva el minimo privilegio cuando aparezcan tablas nuevas.
