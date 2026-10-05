# Informe del simulacro de incidente

## Secuencia ejecutada y resultado

El simulacro se ejecutó exclusivamente en `food_store_tp_u5_seguridad` con el login local `soporte_operador` y el rol de grupo `rol_soporte`. Se realizaron tres llamadas fallidas y una exitosa a `fn_autenticar`; la salida real del script muestra `f, f, f, t`. Luego se consultaron 1.000 filas de las únicas columnas autorizadas para soporte: `id_usuario`, `nombre` y `apellido`.

El intento de escalamiento fue `GRANT admin_datos TO soporte_operador`. El bloque SQL capturó `insufficient_privilege` y produjo el aviso `ESCALAMIENTO_BLOQUEADO`. Por lo tanto, el escalamiento no se concedió; las membresias verificadas siguen mostrando solo `rol_soporte` para esa identidad.

## Contraste con la reconstruccion de IA

La reconstruccion identificó correctamente la secuencia de cuatro autenticaciones, la lectura de hasta 1.000 filas y el intento de otorgar una membresia administrativa. También separó adecuadamente la propuesta de contención de una acción automática.

La corrección humana fue necesaria en dos puntos. El fragmento anonimizado no informa si las cuatro autenticaciones devolvieron verdadero o falso: ese dato se confirmó con la salida de `simulacro_incidente.txt`, no con el log. Tampoco demuestra por si solo que el `GRANT` falló: la evidencia decisiva es el aviso capturado por el bloque `DO` y la posterior consulta de membresías. Sería incorrecto afirmar una intrusión exitosa o una elevación de privilegios a partir del log solamente.

## Decision de contencion

En un caso real, el equipo preservaría el fragmento de log y los eventos de auditoría, y deshabilitaría temporalmente el login involucrado con `ALTER ROLE soporte_operador NOLOGIN` mientras revisa si la lectura era legítima. No se ejecutó esa suspensión en el laboratorio porque la lectura y el intento fueron deliberados y se confirmó que el escalamiento fue bloqueado. Después del análisis se revisaría la necesidad de la lectura masiva, se reduciría el límite operativo si no estuviera justificado y se forzaría un reseteo de credenciales solo si la investigación aportara evidencia de compromiso.
