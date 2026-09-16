# TP4 - Plantillas de evidencia y resultados reales

Completar esta hoja solo despues de ejecutar los scripts. No reemplazar planes ni tiempos reales por estimaciones de `cost`.

## Parte 1 - medicion antes/despues

| Consulta | Algoritmo(s) de join antes | Cambio aplicado | Algoritmo(s) de join despues | Tiempo antes (ms) | Tiempo despues (ms) | Mejora (x) | Decision |
|---|---|---|---|---:|---:|---:|---|
| Q1 Facturacion por categoria y mes | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | Aceptar / rechazar segun plan real |
| Q2 Ranking de clientes por gasto | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | Aceptar / rechazar segun plan real |
| Q3 Ventas mensuales del producto 100001 | Parallel Seq Scan de `detalle_pedido` | `idx_tp4_detalle_producto_pedido` | Index Only Scan | 65.141 | 0.460 | 141.61 | Aceptado: menor lectura de detalle y tiempo real |

Guardar el texto o capturas completas de los cuatro planes: Q1 antes/despues y Q2 antes/despues.

## Parte 3 - equivalencia

| Control | Resultado esperado | Resultado real |
|---|---:|---:|
| `spec_1_ia_menos_propia` | 0 | 0 |
| `spec_1_propia_menos_ia` | 0 | 0 |
| `spec_2_ia_menos_propia` | 0 | 0 |
| `spec_2_propia_menos_ia` | 0 | 0 |

## Parte 4 - competencia

| Equipo | Estrategia aplicada | Tiempo antes (ms) | Tiempo despues (ms) | Mejora (x) | Nodos de plan que justifican la decision |
|---|---|---:|---:|---:|---|
| Santiago Barretto | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE |
