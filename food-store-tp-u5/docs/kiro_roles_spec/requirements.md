# Requirements de roles Food Store

> Nota de trazabilidad: la consigna nombra Kiro y OpenCode. En este entorno se utilizo Codex como asistente de especificacion, implementacion y revision; no se atribuye el trabajo a una herramienta que no se uso.

## Objetivo

Aplicar minimo privilegio en la copia `food_store_tp_u5_seguridad`: cada identidad recibe solo las operaciones necesarias y los datos personales quedan separados de catalogos, pedidos, reportes y auditoria.

## Roles y necesidades

| Rol | Tipo | Operacion habilitada y justificacion |
|---|---|---|
| `rol_app_lectura` | Grupo | Lee productos y categorias para presentar el catalogo de la aplicacion. No necesita usuarios ni auditoria. |
| `rol_app_escritura` | Grupo | Inserta y actualiza pedidos y detalles para registrar una venta. No puede borrar historico. |
| `rol_soporte` | Grupo | Consulta identificador, nombre y apellido de usuario para tickets y ejecuta el reseteo controlado. No ve email ni hash. |
| `rol_reportes` | Grupo | Lee solamente la vista agregada de ventas por categoria. |
| `rol_auditoria` | Grupo | Lee eventos tecnicos de auditoria sin acceso a la tabla de usuarios. |
| `app_web` | Login | Ejecuta la aplicacion mediante los dos roles de catalogo y escritura. |
| `soporte_operador` | Login | Representa una cuenta de soporte para el laboratorio de incidente. |
| `admin_datos` | Login | Mantiene usuarios y consulta auditoria, sin superusuario ni creacion de roles. |

## Requisitos verificables

1. `app_web` no puede leer directamente `usuario`.
2. `soporte_operador` solo puede seleccionar `id_usuario`, `nombre` y `apellido` de `usuario`.
3. Ningun rol de bajo privilegio puede otorgarse `admin_datos`.
4. `rol_reportes` recibe una vista, no tablas operativas.
5. Las futuras tablas y funciones creadas por `postgres` no quedan expuestas a `PUBLIC`.
