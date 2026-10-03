# Informe tecnico - TP Unidad 4: FNBC y desnormalizacion controlada

**Estudiante:** Santiago Barretto<br>
**Base de laboratorio:** `food_store_tp_u4_fnbc`<br>
**Motor:** PostgreSQL 18.4<br>
**Fecha de ejecucion:** 03/10/2026

## 1. Parte 1 - ControlLoteAlmacen y FNBC

### Dependencias funcionales y claves candidatas

Para `R(LoteID, DepositoID, ResponsableControlID)` las reglas de negocio determinan:

1. `{LoteID, DepositoID} -> ResponsableControlID`: para un lote y deposito dados se designa un unico responsable.
2. `ResponsableControlID -> DepositoID`: un responsable pertenece a un unico deposito.

Las clausuras relevantes son:

| Conjunto | Clausura | Conclusion |
|---|---|---|
| `{LoteID, DepositoID}` | `{LoteID, DepositoID, ResponsableControlID}` | Clave candidata |
| `{LoteID, ResponsableControlID}` | `{LoteID, ResponsableControlID, DepositoID}` | Clave candidata |
| `{ResponsableControlID}` | `{ResponsableControlID, DepositoID}` | No es clave: falta `LoteID` |
| `{LoteID}` | `{LoteID}` | No es clave |
| `{DepositoID}` | `{DepositoID}` | No es clave |

El conjunto completo de claves candidatas es `{LoteID, DepositoID}` y `{LoteID, ResponsableControlID}`. Los tres atributos son primos porque todos aparecen en al menos una clave candidata; no existen atributos no primos.

### Violacion de FNBC y anomalias

La relacion no cumple FNBC por `ResponsableControlID -> DepositoID`. En FNBC, el determinante de toda dependencia funcional no trivial debe ser superclave. Sin embargo, `ResponsableControlID+ = {ResponsableControlID, DepositoID}` y no obtiene `LoteID`, por lo que no es superclave.

- **Insercion:** no puede registrarse que el responsable 803 pertenece al deposito 30 hasta asignarlo a algun lote; el dato maestro depende de una fila operativa.
- **Borrado:** si se elimina el control `(503, 31, 802)`, se pierde tambien el unico dato que indica que 802 pertenece al deposito 31.
- **Actualizacion:** mover al responsable 801 de deposito obliga a cambiar las filas de los lotes 501 y 502. Si solo se actualiza una, se contradice la regla de negocio.

### Descomposicion sin perdida

Se descompuso por la dependencia violatoria en:

```text
responsable_deposito(ResponsableControlID PK, DepositoID FK)
control_lote_responsable(LoteID, ResponsableControlID, PK(LoteID, ResponsableControlID))
```

El atributo comun es `ResponsableControlID`. Este atributo es clave de `responsable_deposito`, pues determina `DepositoID`; por el criterio de descomposicion sin perdida, la reunion natural de ambas relaciones es sin perdida. El script `tp_fnbc_control_lote.sql` migra la instancia y la vista `vw_control_lote_almacen_compatibilidad` reconstruye la relacion original.

**Verificacion real:** los controles `original_menos_vista` y `vista_menos_original` devolvieron ambos `0` diferencias. La verificacion de la dependencia `ResponsableControlID -> DepositoID` no devolvio filas.

## 2. Parte 2 - Top diario de categorias

### Contexto de la medicion

La copia provino de `food_store_tp5_base`, con 50.000 productos, 200.000 pedidos y 400.000 detalles. Se prepararon en la copia los campos `eliminado` y `subtotal` requeridos por la consulta de la guia. Las fechas de laboratorio se desplazaron dentro de la copia para que `CURRENT_DATE` fuera 03/10/2026 y contuviera 311 pedidos y 622 detalles. Las bases fuente no fueron modificadas.

### Captura textual - consulta normalizada (antes)

```text
Parallel Seq Scan on public.detalle_pedido dp
  Filter: (NOT dp.eliminado)
  actual rows=133333.33 loops=3

Parallel Seq Scan on public.pedido ped
  Filter: ((NOT ped.eliminado) AND ((ped.fecha)::date = CURRENT_DATE))
  Rows Removed by Filter: 199689

Execution Time: 49.870 ms
```

El trabajo dominante provino de los recorridos paralelos y de la reunion sobre las tablas operativas; en especial se recorrio `detalle_pedido` completo para obtener solamente los detalles del dia.

### Patron elegido y sincronizacion

Se eligio una **vista materializada** `mv_tp_u4_top_categorias_dia` con una fila por fecha y categoria. La medicion previa de 49,870 ms evidencia que es razonable precalcular este agregado para un panel consultado muchas veces por minuto. La estructura se refresca mediante triggers de nivel sentencia sobre `detalle_pedido`, `pedido`, `producto` y `categoria`, que son todas las tablas que pueden modificar el resultado.

El refresh se ejecuta en la misma transaccion que la modificacion de la fuente: una operacion confirmada actualiza la vista y una operacion revertida revierte tambien su refresh. Las tablas normalizadas siguen siendo la fuente de verdad; la vista puede eliminarse y recrearse desde ellas, por lo que la desnormalizacion es reversible sin perdida de informacion.

### Captura textual - consulta desnormalizada (despues)

```text
Bitmap Index Scan on ix_mv_tp_u4_top_categorias_fecha_monto
  Index Cond: (mv_tp_u4_top_categorias_dia.fecha = CURRENT_DATE)

Bitmap Heap Scan on public.mv_tp_u4_top_categorias_dia
  actual rows=2 loops=1

Execution Time: 0.344 ms
```

| Antes: modelo normalizado | Despues: vista materializada |
|---|---|
| **Tiempo de ejecucion:** 49,870 ms | **Tiempo de ejecucion:** 0,344 ms |
| **Nodo dominante:** `Parallel Seq Scan` / `Parallel Hash Join` | **Nodo dominante:** `Bitmap Heap Scan`, apoyado por `Bitmap Index Scan` |
| **Acceso:** detalle, producto, categoria y pedido | **Acceso:** solo `mv_tp_u4_top_categorias_dia` |

La consulta desnormalizada redujo el tiempo medido aproximadamente un 99,31 %. El objetivo no es reemplazar el modelo normalizado, sino utilizar una estructura derivada para este reporte acotado.

### Auditoria y prueba de sincronizacion

El script compara mediante `FULL OUTER JOIN` la agregacion obtenida desde las cuatro tablas contra la vista materializada. La auditoria sobre la base migrada devolvio cero filas. Tambien se inserto un pedido y detalle de prueba dentro de `BEGIN ... ROLLBACK`: luego del trigger, la auditoria dentro de esa transaccion devolvio `0` diferencias y `ROLLBACK` dejo la base sin ese dato de prueba.

## 3. Artefactos y reproducibilidad

- `00_preparar_base_u4.sql`: prepara solo la copia y ejecuta `ANALYZE`.
- `tp_fnbc_control_lote.sql`: implementacion verificable de la Parte 1.
- `tp_desnormalizacion_top_categorias.sql`: implementacion, medicion y auditoria de la Parte 2.
- `evidencia/20261003_153429/`: salidas directas de PostgreSQL usadas en este informe.
- `run_tp_u4.ps1`: crea una copia segura desde `food_store_tp5_base` y ejecuta los tres scripts, sin borrar una base existente.

Cada afirmacion del informe puede comprobarse en los scripts y en la evidencia indicada.
