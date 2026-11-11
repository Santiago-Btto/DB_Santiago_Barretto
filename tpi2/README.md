# TPI Food Store · Segunda entrega (Unidades 4 a 8)

Esta rama reúne los trabajos de `tp6/` (Unidad 4), `tp7/` (Unidad 5), `tp8/` (Unidad 6), `tp9/` (Unidad 7) y `tp10/` (Unidad 8). `main` conserva sólo un enlace a Unidad 8 por la organización acordada previamente. Para que el corrector vea las tres capas de datos, debe abrir esta rama.

Archivos de entrada para la corrección:

1. `DB_Santiago_Barretto_TPI2.pdf`: informe técnico breve para la plataforma.
2. `informe_tecnico.md`: misma información en texto con rutas de evidencia.
3. `checklist_entrega.md`: evaluación objetiva, requisito por requisito, de los 14 puntos.
4. `plan_reversion_u4.md` y `ensayo_reversion_u4.sql`: procedimiento y prueba no destructiva de rollback de la descomposición FNBC.
5. `u5_endurecer_auditoria.sql`: corrección de permisos de auditoría, aplicada en la copia de Unidad 5.
6. `auditar_scripts.py`: inventario estático de scripts versionados, hashes y comprobación sintáctica donde procede; las salidas quedan en `evidencia/`.
7. `evidencia/opencode_revision_global.txt`: revisión de IA con decisiones humanas, alcance y límites declarados.
8. `programar_mantenimiento_u6.ps1` y `ejecutar_mantenimiento_u6.ps1`: tarea diaria de Windows para chequeo, validación y respaldo; `evidencia/u6_tarea_programada.txt` contiene su ejecución real y `opencode_revision_scheduler.txt` el contraste con IA.

La corrección no debe tratar la presencia de specs con formato Kiro como prueba de que Kiro se ejecutó. Las faltas formales pendientes se enumeran al final del checklist y del informe. Para repetir las pruebas de SQL, usar sólo las copias de laboratorio indicadas por los guardas de cada script.

La tarea local se registra con `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tpi2\programar_mantenimiento_u6.ps1 -Hora 20:00`. Se ejecuta con el usuario que tiene la sesión iniciada, no almacena credenciales y se puede quitar con `Unregister-ScheduledTask -TaskName FoodStore-BDII-U6-Diario -Confirm:$false`. La restauración queda bajo supervisión humana porque el script se niega a sobreescribir su base de prueba.
