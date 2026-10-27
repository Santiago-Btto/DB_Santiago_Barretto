param(
    [string]$PgBin = 'C:\Program Files\PostgreSQL\18\bin',
    [string]$DbHost = 'localhost',
    [int]$DbPort = 5432,
    [string]$DbUser = 'postgres'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$database = 'foodstore'
$backupDir = Join-Path $PSScriptRoot 'backups'
$logDir = Join-Path $PSScriptRoot 'logs'
$validationFile = Join-Path $PSScriptRoot 'validation.sql'
$psql = Join-Path $PgBin 'psql.exe'
$pgDump = Join-Path $PgBin 'pg_dump.exe'
$pgRestore = Join-Path $PgBin 'pg_restore.exe'

foreach ($path in @($psql, $pgDump, $pgRestore, $validationFile)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Archivo requerido no encontrado: $path"
    }
}
New-Item -ItemType Directory -Path $backupDir, $logDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$dumpFile = Join-Path $backupDir "foodstore_$stamp.dump"
$manifestFile = Join-Path $backupDir "foodstore_$stamp.json"
$logFile = Join-Path $logDir "backup_$stamp.log"
if ((Test-Path -LiteralPath $dumpFile) -or (Test-Path -LiteralPath $manifestFile)) {
    throw "Ya existe un respaldo con la marca $stamp. Reintentar en otro segundo."
}

function Write-Log([string]$message) {
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'), $message
    Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8
    Write-Host $line
}

function Invoke-PgTool([string]$executable, [string[]]$toolArgs) {
    $output = & $executable @toolArgs 2>&1
    $code = $LASTEXITCODE
    foreach ($line in @($output)) { if ($null -ne $line -and "$line".Length -gt 0) { Write-Log "$line" } }
    if ($code -ne 0) { throw "$(Split-Path $executable -Leaf) termino con codigo $code" }
    return @($output)
}

function Get-Validation([string]$databaseName) {
    $lines = Invoke-PgTool $psql @('-X', '-w', '-v', 'ON_ERROR_STOP=1', '-At', '-F', '|',
        '-h', $DbHost, '-p', "$DbPort", '-U', $DbUser, '-d', $databaseName,
        '-f', $validationFile)
    $result = @{}
    foreach ($line in $lines) {
        $parts = "$line".Trim() -split '\|', 2
        if ($parts.Count -ne 2 -or $parts[1] -notmatch '^\d+$') {
            throw "Salida de validacion inesperada: $line"
        }
        $result[$parts[0]] = [long]$parts[1]
    }
    if ($result.Count -ne 7) { throw "Se esperaban 7 controles; llegaron $($result.Count)" }
    return $result
}

try {
    Write-Log "Inicio de respaldo custom de $database"
    $baseline = Get-Validation $database
    if ($baseline['productos_invalidos'] -ne 0 -or $baseline['detalles_invalidos'] -ne 0) {
        throw 'La base principal ya contiene datos invalidos; corregir antes del simulacro.'
    }
    $startedAt = Get-Date
    Write-Log "Inicio pg_dump: $($startedAt.ToString('o'))"
    Invoke-PgTool $pgDump @('-w', '-h', $DbHost, '-p', "$DbPort", '-U', $DbUser,
        '-d', $database, '-Fc', '-f', $dumpFile) | Out-Null
    $completedAt = Get-Date
    $dumpInfo = Get-Item -LiteralPath $dumpFile
    if ($dumpInfo.Length -le 0) { throw 'pg_dump devolvio exito, pero el archivo esta vacio.' }
    Invoke-PgTool $pgRestore @('--list', $dumpFile) | Out-Null
    $sha256 = (Get-FileHash -LiteralPath $dumpFile -Algorithm SHA256).Hash
    $manifest = [ordered]@{
        database = $database
        backup_started_at = $startedAt.ToString('o')
        backup_completed_at = $completedAt.ToString('o')
        dump_file = (Split-Path $dumpFile -Leaf)
        bytes = $dumpInfo.Length
        sha256 = $sha256
        validation = $baseline
    }
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestFile -Encoding UTF8
    Write-Log "OK pg_dump exit=0, pg_restore --list exit=0, bytes=$($dumpInfo.Length), sha256=$sha256"
    Write-Log "Manifest: $manifestFile"
    Write-Log "Archivo: $dumpFile"
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
