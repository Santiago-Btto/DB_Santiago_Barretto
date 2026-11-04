# Evidencia verificable - Unidad 8

El laboratorio se ejecutó el 04/11/2026 en PostgreSQL 18.4, Python SQLite 3.49.1 y MongoDB 9.0.4 ya preparado en TP9. No se publicaron contraseñas ni datos de clientes. Las salidas no son plantillas: provienen de las ejecuciones registradas.

| Archivo | Qué prueba |
|---|---|
| `evidencia/resultado_laboratorio.txt` | Creación de copia, C1-C7, errores de integridad, hashes y conteos PostgreSQL antes/después del semáforo. |
| `evidencia/snapshots/c1_inicial.csv`, `c2_precio_cambiado.csv`, `c3_stock_y_precio.csv`, `c4_baja_logica.csv` | Las cuatro instantáneas sucesivas, con hora real; la última conserva la lápida `100003`. |
| `movil/servidor_snapshot.csv` | CSV final exportado de `v_snapshot_movil`; importado a `snapshot_servidor`. |
| `movil/foodstore_movil.db` y `evidencia/consultas_sqlite.txt` | Base local con tablas `STRICT`, cola final, catálogo, `integrity_check=ok` y ninguna FK rota. |
| `evidencia/postgresql_verificacion.txt` | Fuente y copia: pedidos y estado de los cuatro productos después del laboratorio. |
| `evidencia/mongodb_tp9_verificacion.txt` | Colección real de TP9: 20 pedidos, ocho con el producto `100001`. |
| `evidencia/opencode_diseno_respuesta.txt`, `opencode_revision_respuesta.txt` | Respuestas finales reales del agente Plan; las decisiones críticas están en `docs/bitacora_ia.md` y `docs/revision_opencode.md`. |
| `evidencia/revision_u6_consultas.txt` | Dos `SELECT EXISTS` reales para descartar un supuesto fallo concreto del script de Unidad 6. |

La base `foodstore_tp10_u8` es una copia local no versionada; se recrea con `run_lab.py` a partir de `foodstore`. La evidencia del TP9 continúa en `tp9/` y su colección MongoDB no se modificó en este trabajo.
