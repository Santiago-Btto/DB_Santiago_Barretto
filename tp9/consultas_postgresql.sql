-- TP9 / Unidad 7. Ejecutar sobre foodstore.
-- La muestra es exactamente la migrada; no se comparan 20 documentos con
-- los 200.000 pedidos del origen. Producto seleccionado: 100001.
-- Umbral de total: 10000.00, que separa seis pedidos de la muestra.
-- pedido no tiene estado; se proyecta la marca honesta de ausencia.

-- A. Todos los pedidos migrados: ID y estado documental derivado.
WITH muestra AS (
    SELECT unnest(ARRAY[
        400001,400002,400003,400004,400005,400006,400007,
        400008,400009,400010,400011,400012,400013,
        405882,450001,455882,500001,505882,550001,555882
    ]::bigint[]) AS id_pedido
)
SELECT p.id_pedido, 'sin_estado_en_origen'::text AS estado
FROM pedido p JOIN muestra m USING (id_pedido)
ORDER BY p.id_pedido;

-- B. Equivalente al filtro MongoDB estado = sin_estado_en_origen.
WITH muestra AS (
    SELECT unnest(ARRAY[
        400001,400002,400003,400004,400005,400006,400007,
        400008,400009,400010,400011,400012,400013,
        405882,450001,455882,500001,505882,550001,555882
    ]::bigint[]) AS id_pedido
), documental AS (
    SELECT p.id_pedido, 'sin_estado_en_origen'::text AS estado
    FROM pedido p JOIN muestra m USING (id_pedido)
)
SELECT 'B_estado' AS consulta, COUNT(*) AS cantidad,
       STRING_AGG(id_pedido::text, ',' ORDER BY id_pedido) AS ids
FROM documental WHERE estado = 'sin_estado_en_origen';

-- C. Equivalente a lineas.id_producto = 100001 (sin duplicar pedidos).
WITH muestra AS (
    SELECT unnest(ARRAY[
        400001,400002,400003,400004,400005,400006,400007,
        400008,400009,400010,400011,400012,400013,
        405882,450001,455882,500001,505882,550001,555882
    ]::bigint[]) AS id_pedido
), coincidentes AS (
    SELECT p.id_pedido FROM pedido p JOIN muestra m USING (id_pedido)
    WHERE EXISTS (
        SELECT 1 FROM detalle_pedido d
        WHERE d.id_pedido = p.id_pedido AND d.id_producto = 100001
    )
)
SELECT 'C_producto' AS consulta, COUNT(*) AS cantidad,
       STRING_AGG(id_pedido::text, ',' ORDER BY id_pedido) AS ids
FROM coincidentes;

-- D. Comprobacion adicional: total historico > 10000.00.
WITH muestra AS (
    SELECT unnest(ARRAY[
        400001,400002,400003,400004,400005,400006,400007,
        400008,400009,400010,400011,400012,400013,
        405882,450001,455882,500001,505882,550001,555882
    ]::bigint[]) AS id_pedido
), importes AS (
    SELECT p.id_pedido, SUM(d.cantidad * d.precio_unitario) AS total
    FROM pedido p JOIN muestra m USING (id_pedido)
    JOIN detalle_pedido d USING (id_pedido)
    GROUP BY p.id_pedido
)
SELECT 'D_total' AS consulta, COUNT(*) AS cantidad,
       STRING_AGG(id_pedido::text, ',' ORDER BY id_pedido) AS ids
FROM importes WHERE total > 10000.00;

-- E. Filtro adicional por un atributo de negocio que SI existe en origen.
WITH muestra AS (
    SELECT unnest(ARRAY[
        400001,400002,400003,400004,400005,400006,400007,
        400008,400009,400010,400011,400012,400013,
        405882,450001,455882,500001,505882,550001,555882
    ]::bigint[]) AS id_pedido
), coincidentes AS (
    SELECT p.id_pedido FROM pedido p JOIN muestra m USING (id_pedido)
    WHERE p.forma_pago = 'TARJETA'
)
SELECT 'E_forma_pago' AS consulta, COUNT(*) AS cantidad,
       STRING_AGG(id_pedido::text, ',' ORDER BY id_pedido) AS ids
FROM coincidentes;
