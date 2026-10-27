param(
    [string]$SourceDatabase = 'food_store_tp5_base',
    [string]$Database = 'food_store_tp_u5_seguridad',
    [string]$HostName = 'localhost',
    [int]$Port = 5432,
    [string]$AdminUser = 'postgres',
    [string]$PsqlPath = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$createdb = Join-Path (Split-Path -Parent $PsqlPath) 'createdb.exe'
$evidence = Join-Path $root ('evidencia\' + (Get-Date -Format 'yyyyMMdd_HHmmss'))

if (-not (Test-Path -LiteralPath $PsqlPath) -or -not (Test-Path -LiteralPath $createdb)) {
    throw 'No se encontro psql/createdb. Indicar -PsqlPath con la ruta de PostgreSQL.'
}

$exists = & $PsqlPath -h $HostName -p $Port -U $AdminUser -d postgres -X -tAc "SELECT 1 FROM pg_database WHERE datname = '$Database';"
if ($exists -eq '1') {
    throw "La copia '$Database' ya existe. El runner no borra ni reemplaza bases: usar otro nombre o eliminar manualmente solo esa copia cuando ya no se necesite."
}

New-Item -ItemType Directory -Path $evidence -Force | Out-Null
& $createdb -h $HostName -p $Port -U $AdminUser --template=$SourceDatabase $Database
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la copia de laboratorio.' }

foreach ($relative in @('00_preparar_base_u5.sql', 'sql\roles.sql', 'sql\auditoria_test.sql', 'sql\verificar_permisos.sql', 'sql\usuario_anon.sql')) {
    $script = Join-Path $root $relative
    $output = Join-Path $evidence (($relative -replace '[\\/]', '_' -replace '\.sql$', '.txt'))
    & $PsqlPath -h $HostName -p $Port -U $AdminUser -d $Database -X -v ON_ERROR_STOP=1 -P pager=off -f $script 2>&1 |
        Tee-Object -FilePath $output
    if ($LASTEXITCODE -ne 0) { throw "Fallo $relative. Revisar $output" }
}

& $PsqlPath -h $HostName -p $Port -U $AdminUser -d $Database -X -P pager=off -c '\du' 2>&1 |
    Tee-Object -FilePath (Join-Path $evidence 'du_roles.txt')
if ($LASTEXITCODE -ne 0) { throw 'No se pudo generar la verificacion \du de roles.' }

# El FATAL es intencional: prueba un inicio de sesion fallido sin probar claves reales.
& $PsqlPath -h $HostName -p $Port -U intento_invalido_tp_u5 -d $Database -X -c 'SELECT 1;' 2>&1 |
    Tee-Object -FilePath (Join-Path $evidence 'intento_sesion_fallida.txt')
if ($LASTEXITCODE -eq 0) { throw 'El intento con rol inexistente debia fallar.' }

# El simulacro usa un rol de soporte limitado y debe finalizar en 0: el DO interno
# captura el permiso denegado del escalamiento y lo deja como evidencia esperada.
& $PsqlPath -h $HostName -p $Port -U soporte_operador -d $Database -X -v ON_ERROR_STOP=1 -P pager=off -f (Join-Path $root 'sql\simulacro_incidente.sql') 2>&1 |
    Tee-Object -FilePath (Join-Path $evidence 'simulacro_incidente.txt')
if ($LASTEXITCODE -ne 0) { throw 'El simulacro no finalizo correctamente.' }

Write-Host "TP Unidad 5 ejecutado. Evidencia local: $evidence"
Write-Host 'Revisar los fragmentos de log y anonimizarlos antes de versionarlos o entregarlos.'
