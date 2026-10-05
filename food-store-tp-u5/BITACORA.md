# Bitacora de uso de IA

Se utilizó Codex como asistente de planificación, implementación y revisión. La consigna menciona OpenCode y Kiro; esta bitácora registra la herramienta realmente utilizada, sin atribuir acciones a software no usado.

| Parte | Prompt enviado a la IA | Respuesta relevante resumida | Validacion o correccion humana aplicada |
|---|---|---|---|
| A - Roles | "Diseña roles de mínimo privilegio para catalogo, pedidos, soporte, reportes y auditoria." | Propuso separar roles de grupo y logins, y otorgar permisos por objeto. | Se rechazó la sugerencia amplia de `GRANT ALL ON ALL TABLES` para administración y se concedieron solo `SELECT, INSERT, UPDATE, DELETE` a los objetos justificados. Soporte recibió `SELECT` por columna. |
| B - Auditoria | "Indica una configuracion local de PostgreSQL que permita registrar conexiones y pruebas de lectura, insercion y actualizacion." | Propuso `log_connections`, `log_disconnections`, `log_statement` y un prefijo de linea identificable. | Se aplicó en el servidor local con `ALTER SYSTEM` y se verificó con una sesion nueva. Se documentó que `trust` sigue activo en pg_hba.conf y que no equivale a autenticacion segura. |
| C - Incidente | "Reconstruye el log anonimizado, separando hechos e inferencias, y propone contencion sin ejecutar cambios." | Identificó las llamadas, la lectura masiva y el intento de membresía; recomendó preservar evidencia antes de intervenir. | Se verificó con la salida real que tres autenticaciones fallaron, una tuvo éxito y el escalamiento fue bloqueado. La IA no podía deducir esos resultados solo del log, por lo que no se aceptó una conclusión de compromiso exitoso. |
| D - Anonimizacion | "Propone una anonimizacion determinista de usuario que preserve una agregacion por rol y mes." | Propuso sintetizar nombre, apellido y email, conservar rol y fecha, y comparar con `EXCEPT`. | Se excluyó el hash de contrasena de `usuario_anon`. Las dos consultas agregadas se ejecutaron y ambos sentidos de `EXCEPT` devolvieron 0 diferencias. |
| E - Revision | "Revisa si los artefactos del TP cubren la consigna y si existe evidencia para cada afirmacion." | Señaló la necesidad de conservar scripts, salidas, log anonimo y contraste humano. | Se separaron scripts, documentación y evidencia en `food-store-tp-u5/`; se realizaron commits por parte y se evitó versionar el log completo del servidor. |

## Caso de correccion mas significativo

El caso más importante fue no confundir una entrada de log con una prueba completa de autenticación o escalamiento. La IA podía observar cuatro llamadas a `fn_autenticar` y un bloque con `GRANT`, pero no conocer sus valores de retorno ni el resultado interno del bloque. Se detectó al contrastar la hipótesis con `simulacro_incidente.txt` y con `verificacion_permisos.txt`. La decisión de contención quedó condicionada a esa evidencia adicional y no se automatizó.

## Revision del historial Git

El historial se organizó con commits separados para preparación y roles, auditoría, simulacro, anonimización y documentación final. En una iteración futura se iniciaría el historial de la Unidad 5 antes de crear la copia local, para que el primer commit incluya también la decisión de aislamiento de la base.
