| Ruta | Revisado | Hallazgo (línea) / sin hallazgo prioritario |
|---|---|---|
| tp10/build_informe_pdf.py | sí | sin hallazgo prioritario (rutas Windows L55-57, verificación de evidencia L39-51) |
| tp10/movil/pruebas_sqlite.sql | sí | sin hallazgo prioritario (bloques @expected-error L23-29) |
| tp10/movil/schema_sqlite.sql | sí | sin índices para FKs id_local (L30-33, L43); baja |
| tp10/movil/semaforo.sql | sí | sin hallazgo prioritario (solo PENDIENTE L27-28; UPDATE L36-46) |
| tp10/run_lab.py | sí | parsing frágil de @expected-error (L153-166); md5 L63-69 |
| tp10/servidor_snapshot.sql | sí | fecha_copia no determinista (L21-22) |
| tpi2/auditar_scripts.py | sí | depende de node/pwsh externos (L70-77) |
| tpi2/build_informe.py | sí | tabla fija 2 columnas/ancho (L84) |
| tpi2/ejecutar_mantenimiento_u6.ps1 | sí | $LASTEXITCODE tras pipeline (L29, L45) |
| tpi2/ensayo_reversion_u4.sql | sí | sin hallazgo prioritario (rollback final L54) |
| tpi2/programar_mantenimiento_u6.ps1 | sí | powershell.exe por PATH (L13) |
| tpi2/u5_endurecer_auditoria.sql | sí | sin validación de rol admin_datos (L13-14) |

Hallazgos accionables (máx 4):
1. `tpi2/ejecutar_mantenimiento_u6.ps1:29,45` — código de salida capturado después del pipeline puede no reflejar psql/respaldo → falso OK. Severidad: media.
2. `tpi2/build_informe.py:84` — ancho fijo de 2 columnas; tablas con más columnas se desbordan. Severidad: media.
3. `tpi2/auditar_scripts.py:70-77` — inventario no reproducible sin node/pwsh instalados. Severidad: media.
4. `tp10/run_lab.py:153-166` — parsing de bloques por texto es frágil ante cambios de formato. Severidad: baja.
