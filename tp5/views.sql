-- Vistas de reportes de TP5.
-- Se completa incrementalmente y cada vista queda además en views/.

-- Productos y categorías vigentes para el catálogo de reportes.
CREATE OR REPLACE VIEW vw_tp5_productos_vigentes_categoria AS
SELECT prod.id_producto,
       prod.nombre AS producto,
       prod.descripcion,
       prod.precio_lista,
       prod.stock,
       cat.id_categoria,
       cat.nombre AS categoria
FROM producto AS prod
JOIN categoria AS cat ON cat.id_categoria = prod.id_categoria
WHERE prod.activo
  AND cat.activo;
