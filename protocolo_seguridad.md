# Protocolo de seguridad

Este material es exclusivo para laboratorio académico. No se debe ejecutar sobre producción ni sobre una base con datos que no se puedan restaurar.

## Preparación en Windows

Abrir PowerShell en la raíz del proyecto y verificar que `psql` y `pg_dump` estén disponibles:

```powershell
psql --version
pg_dump --version
New-Item -ItemType Directory -Force backups
```

Crear la base de trabajo y cargar el esquema. Ejecutar estos comandos solo si el rol indicado posee permisos; se solicita la contraseña de forma interactiva.

```powershell
createdb -U postgres food_store_tp2
psql -U postgres -d food_store_tp2 -v ON_ERROR_STOP=1 -f schema.sql
```

Crear una plantilla reutilizable después de revisar que `food_store_tp2` es la base recién cargada:

```powershell
createdb -U postgres -T food_store_tp2 food_store_base
```

Para reiniciar una práctica, crear una nueva base desde la plantilla, nunca sobrescribir una existente:

```powershell
createdb -U postgres -T food_store_base food_store_tp2_sesion
```

## Respaldo y restauración

Antes de cambios de estructura, generar un respaldo con marca de tiempo:

```powershell
$marca = Get-Date -Format "yyyyMMdd-HHmmss"
pg_dump -U postgres -Fc -f "backups\food_store_tp2-$marca.backup" food_store_tp2
```

Restaurar únicamente en una base nueva y vacía:

```powershell
createdb -U postgres food_store_tp2_restaurada
pg_restore -U postgres -d food_store_tp2_restaurada "backups\ARCHIVO.backup"
```

## Protocolo de ejecución

1. Confirmar la conexión con `psql -U postgres -d food_store_tp2 -c "SELECT current_database(), current_user;"`.
2. Revisar primero los `SELECT` de cada script y ejecutar cambios de estructura dentro de una transacción manual.
3. Para revisión o prueba temporal usar siempre `BEGIN;` y finalizar con `ROLLBACK;`. Usar `COMMIT;` solo tras revisión explícita y respaldo verificado.
4. Las prácticas de concurrencia requieren dos sesiones independientes de `psql`; no cerrar ni mezclar sus transacciones hasta completar cada escenario.
