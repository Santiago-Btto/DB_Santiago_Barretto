# Evidencia de ejecución - TP9 / Unidad 7

Fecha local: 02/11/2026. PostgreSQL 18.4 (`foodstore`) y MongoDB Community 9.0.4 (`foodstore_tp9.pedidos`). La rama de trabajo es `codex/tp9-unidad7-nosql`.

| Control | Resultado real | Archivo |
|---|---|---|
| Esquema relacional | `pedido` tiene `id_pedido, fecha, id_cliente, forma_pago`; no tiene `estado`; cuatro FK del modelo | `postgresql_modelo.txt` |
| Procedencia | Los 20 clientes seleccionados usan direcciones `example.invalid` de carga sintética; el export no contiene email/teléfono | `postgresql_modelo.txt`, `export_integridad.txt` |
| Exportación | 20 documentos, 18.015 bytes; SHA-256 registrado | `export_integridad.txt` |
| Migración | 20 documentos y 40 líneas en una colección real | `migracion_observada.txt`, `mongodb_coleccion.txt` |
| Integridad | Todos los campos de los 20 documentos y 40 líneas iguales al export; cantidad cero rechazada sin insertar | `mongodb_integridad.txt` |
| Estado `sin_estado_en_origen` | 20 en ambos motores; IDs idénticos | `postgresql_consultas.txt`, `mongodb_consultas.txt`, `comparacion_motores.txt` |
| Producto `100001` | 8 en ambos motores; IDs idénticos | Ídem |
| Total > 10.000,00 | 6 en ambos motores; IDs idénticos | Ídem; `postgresql_umbral.txt` |
| Pago `TARJETA` (adicional) | 7 en ambos motores; IDs idénticos | `comparacion_motores.txt` |
| Seguridad de reejecución | Migración abortó con código 1 al hallar colección existente; no la reemplazó | `guard_existing_collection.txt` |

Los IDs por producto son `400001, 405882, 450001, 455882, 500001, 505882, 550001, 555882`. Los totales de la muestra van de 3.418,00 a 26.099,00; 10.000,00 divide la muestra de forma no trivial. La consulta por estado devuelve los 20 porque ningún pedido del esquema fuente registra un estado; este resultado **no** se presenta como clasificación comercial. La consulta extra por forma de pago usa un valor real y devuelve 7 IDs.

`mongodb_coleccion.txt` muestra un documento con cliente, dos líneas y precios Decimal128. `mongodb_integridad.txt` acredita igualdad de campos después de persistirlos y rechazo por validador. `ia_prompt_respuesta.txt` conserva una respuesta breve de OpenCode; las dos afirmaciones relevantes se contrastan en `IA_CONTRASTE.md`. No se midió rendimiento ni se fabricaron estados.
