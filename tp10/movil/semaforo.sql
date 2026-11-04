-- Solo actualiza la cola local; no abre conexión ni escribe en PostgreSQL.
BEGIN IMMEDIATE;
WITH evaluacion AS (
    SELECT c.solicitud_uuid,
           i.producto_id,
           CASE WHEN i.producto_id IS NULL OR s.id IS NULL OR
                     s.disponible = 0 OR s.eliminado = 1 OR
                     i.cantidad > s.stock_visto THEN 1 ELSE 0 END AS rojo,
           CASE WHEN s.id IS NOT NULL AND
                     i.precio_centavos_visto <> s.precio_centavos
                     THEN 1 ELSE 0 END AS amarillo,
           CASE
             WHEN i.producto_id IS NULL THEN 'borrador sin items'
             WHEN s.id IS NULL THEN 'producto ' || i.producto_id || ' ausente'
             WHEN s.eliminado = 1 THEN 'producto ' || i.producto_id || ' eliminado'
             WHEN s.disponible = 0 THEN 'producto ' || i.producto_id || ' no disponible'
             WHEN i.cantidad > s.stock_visto THEN 'producto ' || i.producto_id || ' stock insuficiente'
             ELSE NULL
           END AS motivo_rojo,
           CASE WHEN s.id IS NOT NULL AND
                     i.precio_centavos_visto <> s.precio_centavos
                     THEN 'producto ' || i.producto_id || ' precio cambiado'
                ELSE NULL END AS motivo_amarillo
    FROM cola_sync c
    LEFT JOIN item_borrador i ON i.id_local = c.id_local
    LEFT JOIN snapshot_servidor s ON s.id = i.producto_id
    WHERE c.estado = 'PENDIENTE'
), resumen AS (
    SELECT solicitud_uuid,
           SUM(rojo) AS rojos,
           SUM(amarillo) AS amarillos,
           group_concat(motivo_rojo, '; ') AS motivo_rojo,
           group_concat(motivo_amarillo, '; ') AS motivo_amarillo
    FROM evaluacion GROUP BY solicitud_uuid
)
UPDATE cola_sync
SET estado = CASE WHEN resumen.rojos > 0 THEN 'RECHAZADO'
                  WHEN resumen.amarillos > 0 THEN 'CONFLICTO'
                  ELSE 'SIMULADO_APROBADO' END,
    motivo = CASE WHEN resumen.rojos > 0 THEN resumen.motivo_rojo
                  WHEN resumen.amarillos > 0 THEN resumen.motivo_amarillo
                  ELSE 'coincide con instantanea del servidor' END,
    resuelto_en = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
FROM resumen
WHERE cola_sync.solicitud_uuid = resumen.solicitud_uuid
  AND cola_sync.estado = 'PENDIENTE';
COMMIT;
