param(
    [string]$PgBin = 'C:\Program Files\PostgreSQL\18\bin',
    [string]$DbHost = 'localhost',
    [int]$DbPort = 5432,
    [string]$DbUser = 'postgres',
    [string]$BackupManifest = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sourceDatabase = 'foodstore'
$restoreDatabase = 'foodstore_restore_test'
$backupDir = Join-Path $PSScriptRoot 'backups'
$logDir = Join-Path $PSScriptRoot 'logs'
$validationFile = Join-Path $PSScriptRoot 'validation.sql'
$psql = Join-Path $PgBin 'psql.exe'
$createdb = Join-Path $PgBin 'createdb.exe'
$pgRestore = Join-Path $PgBin 'pg_restore.exe'
foreach ($path in @($psql, $createdb, $pgRestore, $validationFile)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Archivo requerido no encontrado: $path" }
}
if (-not (Test-Path -LiteralPath $backupDir -PathType Container)) {
    throw 'No hay carpeta de respaldos. Ejecutar primero backup_foodstore.ps1.'
}
if ([string]::IsNullOrWhiteSpace($BackupManifest)) {
    $latest = Get-ChildItem -LiteralPath $backupDir -Filter 'foodstore_*.json' -File |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -eq $latest) { throw 'No hay manifiesto de respaldo exitoso.' }
    $BackupManifest = $latest.FullName
}
$manifestPath = (Resolve-Path -LiteralPath $BackupManifest).Path
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.database -ne $sourceDatabase) { throw 'El manifiesto no corresponde a foodstore.' }
if ([string]$manifest.dump_file -notmatch '^foodstore_\d{8}_\d{6}\.dump$') {
    throw 'Nombre de dump inesperado en el manifiesto.'
}
$dumpFile = Join-Path (Split-Path $manifestPath -Parent) ([string]$manifest.dump_file)
if (-not (Test-Path -LiteralPath $dumpFile -PathType Leaf)) { throw "Falta el dump: $dumpFile" }
$dumpInfo = Get-Item -LiteralPath $dumpFile
if ($dumpInfo.Length -ne [long]$manifest.bytes -or $dumpInfo.Length -le 0) {
    throw 'El tamano del dump no coincide con el manifiesto.'
}
$actualHash = (Get-FileHash -LiteralPath $dumpFile -Algorithm SHA256).Hash
if ($actualHash -ne [string]$manifest.sha256) { throw 'SHA-256 del dump no coincide con el manifiesto.' }

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$logFile = Join-Path $logDir "restore_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

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
    Write-Log "Inicio simulacro: $sourceDatabase -> $restoreDatabase"
    Write-Log "Dump: $dumpFile ($($dumpInfo.Length) bytes; SHA-256 verificado)"
    Invoke-PgTool $pgRestore @('--list', $dumpFile) | Out-Null
    $existsSource = Invoke-PgTool $psql @('-X', '-w', '-At', '-h', $DbHost,
        '-p', "$DbPort", '-U', $DbUser, '-d', 'postgres', '-c',
        "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = '$sourceDatabase');")
    $existsTarget = Invoke-PgTool $psql @('-X', '-w', '-At', '-h', $DbHost,
        '-p', "$DbPort", '-U', $DbUser, '-d', 'postgres', '-c',
        "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = '$restoreDatabase');")
    if ("$($existsSource[-1])" -ne 't') { throw "No existe la base principal $sourceDatabase." }
    if ("$($existsTarget[-1])" -ne 'f') {
        throw "La base $restoreDatabase ya existe. No se borra ni se reemplaza."
    }

    $currentSource = Get-Validation $sourceDatabase
    foreach ($key in @('categoria', 'cliente', 'producto', 'pedido', 'detalle_pedido')) {
        $before = [long]$manifest.validation.PSObject.Properties[$key].Value
        if ($currentSource[$key] -ne $before) {
            Write-Log "AVISO: $key cambio desde el respaldo: antes=$before, ahora=$($currentSource[$key])"
        }
    }

    $backupStart = [datetimeoffset]::Parse([string]$manifest.backup_started_at)
    $simulationStart = [datetimeoffset]::Now
    $rpoSeconds = [math]::Round(($simulationStart - $backupStart).TotalSeconds, 3)
    if ($rpoSeconds -lt 0) { throw 'La hora del respaldo es posterior al inicio del simulacro.' }
    Write-Log "RPO observado (edad desde inicio del respaldo): $rpoSeconds segundos"

    # Inicio del RTO inmediatamente antes de crear la base de prueba.
    $clock = [System.Diagnostics.Stopwatch]::StartNew()
    Invoke-PgTool $createdb @('-w', '-h', $DbHost, '-p', "$DbPort", '-U', $DbUser,
        '--maintenance-db=postgres', $restoreDatabase) | Out-Null
    Write-Log 'Base de restauracion creada.'
    Invoke-PgTool $pgRestore @('-w', '-h', $DbHost, '-p', "$DbPort", '-U', $DbUser,
        '-d', $restoreDatabase, '--no-owner', '--no-privileges', '--exit-on-error', $dumpFile) | Out-Null
    Write-Log 'pg_restore termino sin errores.'

    $restored = Get-Validation $restoreDatabase
    foreach ($key in @('categoria', 'cliente', 'producto', 'pedido', 'detalle_pedido')) {
        $before = [long]$manifest.validation.PSObject.Properties[$key].Value
        if ($restored[$key] -ne $before) {
            throw "Conteo distinto en ${key}: respaldo=$before, restaurado=$($restored[$key])"
        }
    }
    if ($restored['productos_invalidos'] -ne 0 -or $restored['detalles_invalidos'] -ne 0) {
        throw 'Las validaciones logicas no devolvieron cero.'
    }
    $clock.Stop()
    $rtoSeconds = [math]::Round($clock.Elapsed.TotalSeconds, 3)
    Write-Log "VALIDACIONES OK: cinco conteos identicos; productos_invalidos=0; detalles_invalidos=0"
    Write-Log "RTO observado (creacion + restauracion + validacion): $rtoSeconds segundos"
    Write-Log "Metas: RPO <= 86400 s: $($rpoSeconds -le 86400); RTO <= 600 s: $($rtoSeconds -le 600)"
    Write-Log 'SIMULACRO EXITOSO. La base de prueba se conserva para inspeccion.'
} catch {
    if ($null -ne (Get-Variable -Name clock -ErrorAction SilentlyContinue) -and $clock.IsRunning) {
        $clock.Stop()
        Write-Log "RTO parcial hasta el error: $([math]::Round($clock.Elapsed.TotalSeconds, 3)) segundos"
    }
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
