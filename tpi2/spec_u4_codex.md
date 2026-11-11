# Especificación de la migración FNBC · Unidad 4 · Codex

Esta especificación documenta la migración de `tp6/tp_fnbc_control_lote.sql` y su revisión final TPI2. La primera ejecución del TP precedió a este documento; no se afirma que se haya usado Kiro ni que esta spec existiera antes de aquella ejecución. La revisión y las guardas añadidas en TPI2 se hicieron con Codex.

## Requisitos verificables

1. Si un `ResponsableControlID` está asociado con más de un `DepositoID`, la migración **debe fallar antes de escribir las tablas FNBC** y revertir la transacción. No se resuelve un conflicto eligiendo el depósito mínimo.
2. Si la unión de `control_lote_responsable` y `responsable_deposito` difiere de `control_lote_almacen` en cualquiera de los dos sentidos de `EXCEPT`, la migración **debe fallar antes del `COMMIT`**. La relación original se conserva.
3. Si las dependencias y la equivalencia se cumplen, la migración confirma las tablas FNBC y la vista de compatibilidad. Las dos consultas de auditoría posteriores deben devolver 0 diferencias.
4. Para revertir una ejecución ya confirmada, se comprueba equivalencia, se respalda la copia, se eliminan primero vista y luego tablas derivadas dentro de otra transacción y se conserva la tabla original. Un error lleva a `ROLLBACK`.

## Diseño y prueba

La DF `ResponsableControlID -> DepositoID` determina la descomposición en `responsable_deposito` y `control_lote_responsable`. La tabla original permanece como red de seguridad. Ambas guardas son `DO ... RAISE EXCEPTION` dentro de `BEGIN/COMMIT`; `psql -v ON_ERROR_STOP=1` termina con código 3 ante incumplimiento y PostgreSQL revierte la transacción al cerrar la sesión. `tpi2/plan_reversion_u4.md` establece el procedimiento posterior al commit.

Se probaron tres escenarios en copias de laboratorio: instancia válida (`evidencia/u4_migracion_antes_commit.txt`: `DO`, `COMMIT`, 0 diferencias), DF conflictiva (`evidencia/u4_guard_rechaza_df.txt`: código 3, normalizado intacto) y fila derivada extra (`evidencia/u4_guard_rechaza_diferencia.txt`: código 3 antes del commit). Las copias de prueba se eliminaron tras registrar la evidencia.
