-- Abrir dos consolas independientes: psql -U postgres -d food_store_tp2
-- Copiar cada bloque en la sesion indicada y respetar el orden. No hay salida fabricada.

-- PREPARACION (Sesion A, una vez; ejecutar y confirmar antes de los escenarios)
BEGIN;
DELETE FROM detalle_pedido
WHERE id_producto IN (SELECT id_producto FROM producto WHERE nombre LIKE 'LAB_CONC_2026_%');
DELETE FROM producto WHERE nombre LIKE 'LAB_CONC_2026_%';
DELETE FROM categoria WHERE nombre = 'LAB_CONC_2026';
INSERT INTO categoria (nombre, descripcion) VALUES ('LAB_CONC_2026', 'Semilla descartable');
INSERT INTO producto (nombre, precio_lista, stock, activo, id_categoria)
SELECT 'LAB_CONC_2026_PRECIO', 10.00, 10, TRUE, id_categoria FROM categoria WHERE nombre = 'LAB_CONC_2026';
INSERT INTO producto (nombre, precio_lista, stock, activo, id_categoria)
SELECT 'LAB_CONC_2026_BLOQUEO', 15.00, 10, TRUE, id_categoria FROM categoria WHERE nombre = 'LAB_CONC_2026';
COMMIT;

-- ESCENARIO 1: lectura no repetible en READ COMMITTED.
-- Sesion A
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT precio_lista FROM producto WHERE nombre = 'LAB_CONC_2026_PRECIO';
-- Esperar a que Sesion B confirme; luego ejecutar el SELECT siguiente.
SELECT precio_lista FROM producto WHERE nombre = 'LAB_CONC_2026_PRECIO';
COMMIT;

-- Sesion B (entre los dos SELECT de Sesion A)
BEGIN;
UPDATE producto SET precio_lista = 20.00 WHERE nombre = 'LAB_CONC_2026_PRECIO';
COMMIT;

-- ESCENARIO 1B: la misma lectura en REPEATABLE READ.
-- Sesion A
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT precio_lista FROM producto WHERE nombre = 'LAB_CONC_2026_PRECIO';
-- Esperar a que Sesion B confirme; luego repetir el SELECT.
SELECT precio_lista FROM producto WHERE nombre = 'LAB_CONC_2026_PRECIO';
COMMIT;

-- Sesion B (entre los dos SELECT de Sesion A)
BEGIN;
UPDATE producto SET precio_lista = 30.00 WHERE nombre = 'LAB_CONC_2026_PRECIO';
COMMIT;

-- ESCENARIO 2: lectura fantasma de productos activos en READ COMMITTED.
-- Sesion A
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT count(*) AS activos FROM producto
WHERE activo AND id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'LAB_CONC_2026');
-- Esperar el COMMIT de Sesion B y repetir.
SELECT count(*) AS activos FROM producto
WHERE activo AND id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'LAB_CONC_2026');
COMMIT;

-- Sesion B (entre los dos conteos de Sesion A)
BEGIN;
INSERT INTO producto (nombre, precio_lista, stock, activo, id_categoria)
SELECT 'LAB_CONC_2026_FANTASMA', 5.00, 1, TRUE, id_categoria FROM categoria WHERE nombre = 'LAB_CONC_2026';
COMMIT;

-- ESCENARIO 2B: lectura fantasma en REPEATABLE READ.
-- Sesion B (limpieza previa)
DELETE FROM producto WHERE nombre = 'LAB_CONC_2026_FANTASMA';

-- Sesion A
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) AS activos FROM producto
WHERE activo AND id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'LAB_CONC_2026');
-- Esperar el COMMIT de Sesion B y repetir.
SELECT count(*) AS activos FROM producto
WHERE activo AND id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'LAB_CONC_2026');
COMMIT;

-- Sesion B (entre los dos conteos de Sesion A)
BEGIN;
INSERT INTO producto (nombre, precio_lista, stock, activo, id_categoria)
SELECT 'LAB_CONC_2026_FANTASMA', 5.00, 1, TRUE, id_categoria FROM categoria WHERE nombre = 'LAB_CONC_2026';
COMMIT;

-- ESCENARIO 3: espera por bloqueo de fila.
-- Sesion A
BEGIN;
SELECT id_producto FROM producto WHERE nombre = 'LAB_CONC_2026_BLOQUEO' FOR UPDATE;
-- Mantener abierta la transaccion; ejecutar Sesion B. Despues confirmar para liberarla.
COMMIT;

-- Sesion B (mientras Sesion A conserva el FOR UPDATE)
BEGIN;
SELECT id_producto FROM producto WHERE nombre = 'LAB_CONC_2026_BLOQUEO' FOR UPDATE;
-- Esta sentencia debe esperar hasta el COMMIT o ROLLBACK de Sesion A.
COMMIT;

-- LIMPIEZA FINAL (Sesion A, al terminar todas las observaciones)
BEGIN;
DELETE FROM detalle_pedido WHERE id_producto IN (SELECT id_producto FROM producto WHERE nombre LIKE 'LAB_CONC_2026_%');
DELETE FROM producto WHERE nombre LIKE 'LAB_CONC_2026_%';
DELETE FROM categoria WHERE nombre = 'LAB_CONC_2026';
COMMIT;
