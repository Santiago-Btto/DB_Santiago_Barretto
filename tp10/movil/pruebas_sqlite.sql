-- Ejecutar después de importar la primera instantánea y crear la caché.
-- El runner procesa los dos bloques @expected-error por separado y confirma
-- sqlite3.IntegrityError; si se usa sqlite3 CLI, los errores son esperados.
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('11111111-1111-4111-8111-111111111111', 'tablet_feria', 'TARJETA', '2026-11-04T10:00:00Z');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('11111111-1111-4111-8111-111111111111', 100001, 2,
        (SELECT precio_centavos FROM producto_cache WHERE id = 100001));
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('a1111111-1111-4111-8111-111111111111', '11111111-1111-4111-8111-111111111111');
COMMIT;

BEGIN;
INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('99999999-9999-4999-8999-999999999999', 'tablet_feria', 'EFECTIVO', '2026-11-04T10:01:00Z');
ROLLBACK;

-- C1: catálogo disponible consultable sin conexión al servidor.
SELECT id, nombre, precio_centavos, stock_visto
FROM producto_cache WHERE disponible = 1 AND eliminado = 0 ORDER BY id;

-- @expected-error cantidad
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('11111111-1111-4111-8111-111111111111', 100002, 0, 57400);

-- @expected-error producto
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('11111111-1111-4111-8111-111111111111', 999999, 1, 100);
