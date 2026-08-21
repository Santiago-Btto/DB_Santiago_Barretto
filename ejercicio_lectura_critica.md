# Ejercicio de lectura critica

## Script 1: baja masiva de peliculas

Un `UPDATE` sin una condicion de negocio acotada que asigna `activo = false` desactiva todas las filas de la tabla. Agregar una condicion temporal genérica, como `fecha_hora < CURRENT_TIMESTAMP`, tampoco demuestra que una pelicula haya salido de cartelera: esa columna podria representar una funcion, alta o actualizacion y no la vigencia en cartelera.

La correccion exige validar primero el esquema y una regla de negocio verificable. Por ejemplo, si la tabla confirmada es `pelicula`, tiene `fecha_fin_cartel` y esa columna significa efectivamente el fin de exhibicion, se puede previsualizar y aplicar dentro de una transaccion:

```sql
BEGIN;

SELECT id_pelicula, titulo, fecha_fin_cartel
FROM pelicula
WHERE fecha_fin_cartel IS NOT NULL
  AND fecha_fin_cartel < CURRENT_TIMESTAMP
  AND activo IS DISTINCT FROM FALSE;

UPDATE pelicula
SET activo = FALSE
WHERE fecha_fin_cartel IS NOT NULL
  AND fecha_fin_cartel < CURRENT_TIMESTAMP
  AND activo IS DISTINCT FROM FALSE
RETURNING id_pelicula, titulo;

ROLLBACK; -- Reemplazar por COMMIT solo despues de revisar el RETURNING.
```

Los nombres son ilustrativos, no una afirmacion sobre un esquema no provisto. Si no existe una columna que modele el fin de cartelera, primero debe agregarse o definirse la condicion de negocio con el responsable funcional; no es seguro inventarla en el `UPDATE`.

## Script 2: borrado con `NOT IN`

Un predicado `NOT IN (subconsulta)` puede no borrar ninguna fila cuando la subconsulta devuelve al menos un `NULL`. SQL evalua la comparacion con `NULL` como desconocida; entonces `valor NOT IN (...)` tampoco es verdadero para los valores que no coinciden. El problema aparece aunque las filas aparentemente no relacionadas existan.

La forma preferible es `NOT EXISTS`, que correlaciona por una clave no nula y expresa directamente que no hay referencias:

```sql
DELETE FROM pelicula p
WHERE NOT EXISTS (
    SELECT 1
    FROM funcion f
    WHERE f.id_pelicula = p.id_pelicula
);
```

Antes de ejecutar, confirmar nombres de tablas, columnas, claves foraneas y la politica de conservacion de datos. Para una prueba segura, ejecutar primero el mismo predicado como `SELECT`, dentro de `BEGIN`, y terminar con `ROLLBACK` hasta contar con aprobacion explicita.
