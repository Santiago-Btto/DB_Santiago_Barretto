# Plan de reversión de la migración FNBC de Unidad 4

La migración de `tp6/tp_fnbc_control_lote.sql` conserva `control_lote_almacen`; las tablas FNBC y la vista de compatibilidad son derivadas. En la ejecución original, la comparación bidireccional con `EXCEPT` quedó después del `COMMIT`. Por eso, antes de usar este procedimiento se debe comprobar que ambos sentidos devuelvan cero diferencias y que se cumpla `ResponsableControlID -> DepositoID`. El ensayo en `ensayo_reversion_u4.sql` lo exige de forma ejecutable.

Para revertir **en la copia de laboratorio**: respaldar primero la base; iniciar una transacción, ejecutar las guardas del ensayo, eliminar la vista de compatibilidad y las dos tablas derivadas, verificar que el recuento de `control_lote_almacen` coincide con el inicial y confirmar. Si cualquier guarda falla, `ROLLBACK` y análisis manual de diferencias; nunca elegir un depósito con `min()` para resolver un conflicto de dependencia funcional. La tabla original sigue disponible. Las estructuras del reporte desnormalizado son independientes de esta descomposición.

El archivo de ensayo ejecuta los `DROP` dentro de la transacción y termina con `ROLLBACK`; demuestra que el orden de desmontaje funciona sin alterar el laboratorio. No acredita una ejecución real de la aplicación Kiro: las especificaciones existentes se redactaron con Codex.
