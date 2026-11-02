param(
    [string]$PsqlPath = 'C:\Program Files\PostgreSQL\18\bin\psql.exe',
    [string]$MongoShellPath = (Join-Path $env:LOCALAPPDATA 'Programs\mongosh\mongosh.exe')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sqlFile = Join-Path $PSScriptRoot 'consultas_postgresql.sql'
$mongoFile = Join-Path $PSScriptRoot 'consultas_mongodb.js'
foreach ($file in @($PsqlPath, $MongoShellPath, $sqlFile, $mongoFile)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Falta: $file" }
}

$pg = @(& $PsqlPath -X -w -v ON_ERROR_STOP=1 -At -F '|' -h localhost -p 5432 `
    -U postgres -d foodstore -f $sqlFile 2>&1)
if ($LASTEXITCODE -ne 0) { throw 'Fallo la consulta PostgreSQL.' }
$mongo = @(& $MongoShellPath 'mongodb://127.0.0.1:27017/admin' --quiet --file $mongoFile 2>&1)
if ($LASTEXITCODE -ne 0) { throw 'Fallo la consulta MongoDB.' }

function Get-Row([object[]]$lines, [string]$label) {
    $hits = @($lines | Where-Object { "$($_)" -match "(?i)^$label\|" })
    if ($hits.Count -ne 1) { throw "No hay una unica fila $label" }
    $parts = "$($hits[0])" -split '\|', 3
    if ($parts.Count -ne 3) { throw "Formato inesperado para $label" }
    return $parts
}

foreach ($comparison in @(
    @('B_estado', 'B_ESTADO'),
    @('C_producto', 'C_PRODUCTO'),
    @('D_total', 'D_TOTAL'),
    @('E_forma_pago', 'E_FORMA_PAGO')
)) {
    $pgRow = Get-Row $pg $comparison[0]
    $mongoRow = Get-Row $mongo $comparison[1]
    $same = ($pgRow[1] -eq $mongoRow[1] -and $pgRow[2] -ceq $mongoRow[2])
    Write-Output "$($comparison[1])|PostgreSQL=$($pgRow[1])|MongoDB=$($mongoRow[1])|IDs_coinciden=$same"
    Write-Output "IDs|$($pgRow[2])"
    if (-not $same) { throw "Los resultados difieren en $($comparison[1])" }
}
