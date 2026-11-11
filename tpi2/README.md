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
9. `spec_u4_codex.md`, `revision_final_codex.md` y `evidencia/revision_ia_lote_*.md`: spec de la migración, revisión de los scripts de toda la cursada y decisiones sobre los hallazgos.
10. `opencode_variantes/` y `probar_sqlite_opencode.py`: SQL de Unidad 8 generado con OpenCode Build, corregido y adoptado tras prueba diferencial con la versión anterior; resultados en `evidencia/sqlite_opencode_equivalencia.txt` y `sqlite_db_indice_sin_cambio.txt`.

La spec de Unidad 8 fue escrita con **Codex**; `docs/kiro/` conserva el nombre histórico de la consigna y no es prueba de uso de esa aplicación. El checklist registra esta sustitución solicitada por el estudiante y los límites que requieren aprobación de la cátedra. Para repetir las pruebas de SQL, usar sólo las copias de laboratorio indicadas por los guardas de cada script.

El inventario y la prueba diferencial requieren Python 3.12+, Git y SQLite 3.37+. Para comprobar sintaxis de los archivos JavaScript y PowerShell del inventario se necesitan `node` y `pwsh`; los SQL se revisan por lectura y se ejecutan únicamente en sus laboratorios particulares. `build_informe.py` requiere `reportlab` en el Python que se utilice. Los siete lotes de IA registran una fila por cada uno de los 107 scripts del primer corte; el suplemento cubre los tres scripts agregados y relee los tres modificados, para **110/110** en el inventario final.

La tarea local se registra con `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tpi2\programar_mantenimiento_u6.ps1 -Hora 20:00`. Se ejecuta con el usuario que tiene la sesión iniciada, no almacena credenciales y se puede quitar con `Unregister-ScheduledTask -TaskName FoodStore-BDII-U6-Diario -Confirm:$false`. La restauración queda bajo supervisión humana porque el script se niega a sobreescribir su base de prueba.
