# Verificacion de equivalencia de usuario anon

`usuario_anon` conserva exclusivamente el identificador tecnico, el rol de negocio y la fecha de alta. Nombre, apellido y email se sustituyen por valores sinteticos deterministas; el hash de contrasena no se replica.

Las dos consultas agregan por `rol_negocio` y mes de alta. El script `sql/usuario_anon.sql` ejecuta ambas y luego aplica `EXCEPT` en ambos sentidos. La evidencia de la ejecucion debe mostrar `0` diferencias para `real_menos_anonimo` y `anonimo_menos_real`.

No se deben enviar a un asistente de IA nombres, apellidos, emails, hashes de contrasena, direcciones IP, tokens, contenido de pedidos ni fragmentos de logs sin revisar y anonimizar. Para analizar tendencias bastan los atributos no identificables necesarios para el agregado.
