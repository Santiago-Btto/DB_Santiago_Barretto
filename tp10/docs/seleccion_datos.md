# 1.a - Datos de producto que viajan a la tablet

| Viajan en la instantánea de la feria | No viajan |
|---|---|
| `id_producto`, nombre, precio de lista convertido a centavos enteros, stock visto, disponibilidad, lápida (`eliminado`) y hora de copia. | Clientes, usuarios del servidor, contraseñas, correos, teléfonos, detalles de pedidos históricos, costos internos y credenciales. |

La muestra contiene cuatro productos sintéticos; el ID `100001` también aparece en los pedidos documentales de TP9/Unidad 7. PostgreSQL es la fuente de verdad para precio, stock y ventas. La tablet puede leer el catálogo sin señal y guardar borradores, pero una instantánea vieja nunca autoriza una venta.
