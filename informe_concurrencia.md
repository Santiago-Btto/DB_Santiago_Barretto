# Informe de concurrencia

Base de trabajo: `food_store_tp2`. Scripts de apoyo: `sql/03_laboratorio_concurrencia.sql`.

## 1. Lectura no repetible

**Objetivo.** Comparar dos lecturas de `producto.precio_lista` dentro de una transaccion mientras otra sesion actualiza la fila.

**Orden de comandos.** Ejecutar la preparacion. En sesion A: `BEGIN ISOLATION LEVEL READ COMMITTED`, primer `SELECT` del producto `LAB_CONC_2026_PRECIO`; en sesion B: `BEGIN`, `UPDATE ... SET precio_lista = 20.00`, `COMMIT`; en sesion A, segundo `SELECT` y `COMMIT`. Repetir el orden con `REPEATABLE READ` en A y cambio a `30.00` en B.

**Resultado esperado segun PostgreSQL.** En `READ COMMITTED`, cada sentencia ve una instantanea nueva y el segundo valor puede ser `20.00`. En `REPEATABLE READ`, ambas lecturas de A pertenecen a la instantanea inicial y deben conservar el mismo valor, aunque B confirme `30.00`.

**Explicacion asistida por IA.** PostgreSQL implementa `READ COMMITTED` por sentencia y `REPEATABLE READ` por transaccion para estas lecturas, de modo que el segundo nivel evita la lectura no repetible dentro de la misma transaccion.

**Observacion real del motor: PENDIENTE DE EJECUCION.** Registrar aqui los dos valores leidos, mensajes de `BEGIN`/`COMMIT`, version del motor y capturas.

## 2. Lectura fantasma

**Objetivo.** Contar productos activos de la categoria de laboratorio mientras otra sesion inserta un nuevo producto activo.

**Orden de comandos.** Con `READ COMMITTED`, A abre transaccion y ejecuta el primer `count(*)`; B inserta `LAB_CONC_2026_FANTASMA` y confirma; A repite el conteo y confirma. Para `REPEATABLE READ`, B elimina primero la fila fantasma, A abre la transaccion con ese aislamiento y realiza el primer conteo, B vuelve a insertar y confirma, y A realiza el segundo conteo antes de confirmar.

**Resultado esperado segun PostgreSQL.** En `READ COMMITTED`, el segundo conteo puede aumentar en uno. En `REPEATABLE READ`, el segundo conteo debe ser igual al primero porque A conserva su instantanea inicial; la fila insertada por B no es visible para esa transaccion.

**Explicacion asistida por IA.** Una fila fantasma es una fila nueva que satisface el predicado de una consulta repetida. La visibilidad depende de la instantanea asociada a cada nivel de aislamiento.

**Observacion real del motor: PENDIENTE DE EJECUCION.** Registrar ambos conteos por aislamiento y la confirmacion de la insercion de B.

## 3. Espera por bloqueo

**Objetivo.** Evidenciar que un segundo pedido `FOR UPDATE` de una fila espera cuando otra transaccion conserva ese bloqueo sobre ella.

**Orden de comandos.** A ejecuta `BEGIN` y el `SELECT ... FOR UPDATE` de `LAB_CONC_2026_BLOQUEO`, sin confirmar. B ejecuta `BEGIN` y el mismo `SELECT ... FOR UPDATE` de esa fila. Mantener B esperando, confirmar A y luego permitir que B complete su `COMMIT`.

**Resultado esperado segun PostgreSQL.** El segundo `SELECT ... FOR UPDATE` de B queda en espera hasta que A haga `COMMIT` o `ROLLBACK`, porque ambos pedidos requieren un bloqueo de fila incompatible. Tras liberar A, B puede continuar y confirmar.

**Explicacion asistida por IA.** `FOR UPDATE` bloquea la fila seleccionada para operaciones de actualizacion o borrado concurrentes hasta el final de la transaccion que tomó el bloqueo.

**Observacion real del motor: PENDIENTE DE EJECUCION.** Registrar hora de inicio de B, hora de liberacion en A, mensaje final de B y cualquier bloqueo inesperado.

## Checklist de evidencia real

- [ ] Ejecutar preparacion y limpieza final en `food_store_tp2`.
- [ ] Abrir dos sesiones `psql` independientes.
- [ ] Reemplazar cada campo **PENDIENTE DE EJECUCION** por salidas o capturas reales.
- [ ] Conservar comandos, version de PostgreSQL y nivel de aislamiento usado.
- [ ] No presentar resultados esperados como resultados observados.
