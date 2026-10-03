param(
    [string]$SourceDatabase = 'food_store_tp5_base',
    [string]$Database = 'food_store_tp_u4_fnbc',
    [string]$HostName = 'localhost',
    [int]$Port = 5432,
    [string]$UserName = 'postgres',
    [string]$PsqlPath = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$createdb = Join-Path (Split-Path -Parent $PsqlPath) 'createdb.exe'
$evidenceRoot = Join-Path $scriptRoot ('evidencia\' + (Get-Date -Format 'yyyyMMdd_HHmmss'))

if (-not (Test-Path -LiteralPath $PsqlPath)) {
    throw "No se encontro psql en $PsqlPath. Indicar -PsqlPath con la ruta correcta."
}
if (-not (Test-Path -LiteralPath $createdb)) {
    throw "No se encontro createdb junto a psql: $createdb"
}

$exists = & $PsqlPath -h $HostName -p $Port -U $UserName -d postgres -X -tAc "SELECT 1 FROM pg_database WHERE datname = '$Database';"
if ($exists -eq '1') {
    throw "La base destino '$Database' ya existe. No se reemplaza automaticamente: elegi otro nombre o borra solo esa copia si ya no la necesitas."
}

New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null

& $createdb -h $HostName -p $Port -U $UserName --template=$SourceDatabase $Database
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la copia de laboratorio.' }

$scripts = @(
    '00_preparar_base_u4.sql',
    'tp_fnbc_control_lote.sql',
    'tp_desnormalizacion_top_categorias.sql'
)

foreach ($script in $scripts) {
    $scriptPath = Join-Path $scriptRoot $script
    $outputPath = Join-Path $evidenceRoot ($script -replace '\.sql$', '.txt')
    & $PsqlPath -h $HostName -p $Port -U $UserName -d $Database -X -v ON_ERROR_STOP=1 -P pager=off -f $scriptPath 2>&1 |
        Tee-Object -FilePath $outputPath
    if ($LASTEXITCODE -ne 0) { throw "Fallo $script. Revisar $outputPath" }
}

Write-Host "TP U4 ejecutado correctamente. Evidencia: $evidenceRoot"
