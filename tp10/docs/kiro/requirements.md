# Unidad 8 - requisitos EARS (spec para Kiro)

Esta spec se redactó antes de implementar los scripts de la tablet. El nombre oficial de la guía es «TP8, Unidad 8»; `tp10/` mantiene la secuencia del repositorio después de TP9/Unidad 7. Todos los datos de la prueba son sintéticos y se opera sobre una copia PostgreSQL.

| ID | Requisito verificable | Casos |
|---|---|---|
| REQ-01 | WHEN se crea un borrador en la tablet, THE SYSTEM SHALL guardar cabecera, ítems y solicitud en una transacción; WHEN se revierte una transacción o se intenta una cantidad no positiva o un producto inexistente, THE SYSTEM SHALL conservar la base sin filas parciales. | C1, C7 y pruebas COMMIT/ROLLBACK. |
| REQ-02 | WHEN un producto de una solicitud pendiente conserva disponibilidad y stock pero cambia su precio en la instantánea del servidor, THE SYSTEM SHALL marcar CONFLICTO; WHEN el usuario acepta el precio y crea una solicitud nueva, THE SYSTEM SHALL marcar SIMULADO_APROBADO. | C2. |
| REQ-03 | WHEN una solicitud pendiente contiene un producto ausente, no disponible, eliminado o con stock insuficiente en la instantánea del servidor, THE SYSTEM SHALL marcar RECHAZADO y conservar el motivo sin modificar precio, stock ni pedidos en PostgreSQL. | C3, C4. |
| REQ-04 | WHEN todos los ítems de una solicitud pendiente coinciden en precio, disponibilidad y stock, THE SYSTEM SHALL marcar SIMULADO_APROBADO una sola vez; WHEN se reenvía el mismo UUID, THE SYSTEM SHALL rechazar el duplicado y no reevaluar solicitudes ya resueltas. | C5, C6. |

`SIMULADO_APROBADO` es solo una decisión local de laboratorio y nunca crea una venta.
