# 4.c - Guion para ensayo de defensa (10 minutos)

Este guion prepara el ensayo solicitado para la clase de la semana 13. La presentación ante la cátedra requiere al estudiante y no se declara aquí como realizada.

| Minutos | Qué mostrar y explicar |
|---|---|
| 0-2 | Mapa de los tres motores: PostgreSQL manda sobre precio, stock y ventas; MongoDB TP9 conserva 20 pedidos documentales; SQLite mantiene caché y borradores. |
| 2-4 | Abrir `movil/schema_sqlite.sql` y `movil/foodstore_movil.db`. Mostrar `PRAGMA foreign_keys`, las tablas `STRICT`, el catálogo y la lápida de `100003`. |
| 4-7 | Caso C2 en vivo sobre una copia fresca: precio visto 53700 centavos, servidor lo sube a 54700, nueva instantánea, `CONFLICTO`; al aceptar y crear un UUID nuevo resulta `SIMULADO_APROBADO`. Mostrar el log y aclarar que no se creó venta. |
| 7-9 | Hallazgo de OpenCode corregido: el conteo de pedidos y suma de stock no detectaban un cambio de precio; ahora se compara además el hash de precio, stock, actividad y lápida antes/después. |
| 9-10 | Preguntas: C3/C4 dan rojo por stock o baja; C6 impide duplicar UUID; una restauración vieja exige nueva instantánea y revalidación en servidor. |

Comando para repetir el caso con el laboratorio preparado: inspeccionar `evidencia/resultado_laboratorio.txt` y ejecutar `sqlite3 tp10/movil/foodstore_movil.db "SELECT estado,motivo FROM cola_sync ORDER BY rowid;"`. Para una nueva corrida completa, seguir el procedimiento de copia fresca del README.
