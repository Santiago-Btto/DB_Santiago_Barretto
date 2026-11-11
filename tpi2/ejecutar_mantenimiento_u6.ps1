param(
    [string]$PgBin = 'C:\Program Files\PostgreSQL\18\bin',
    [string]$DbHost = 'localhost',
    [int]$DbPort = 5432,
    [string]$DbUser = 'postgres',
    [string]$BackupScript = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$tp8 = Join-Path (Split-Path $PSScriptRoot -Parent) 'tp8'
$psql = Join-Path $PgBin 'psql.exe'
$logDir = Join-Path $tp8 'logs'
if (-not $BackupScript) { $BackupScript = Join-Path $tp8 'backup_foodstore.ps1' }
if (-not (Test-Path -LiteralPath $BackupScript -PathType Leaf)) { throw "Falta script de respaldo: $BackupScript" }
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$log = Join-Path $logDir ('scheduled_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.log')

function Invoke-Checked([string]$label, [string]$scriptFile) {
    "$(Get-Date -Format o) Inicio $label" | Add-Content -LiteralPath $log
    $oldPreference = $ErrorActionPreference
    try {
        # PowerShell 5.1 convierte los NOTICE de psql (stderr) en errores terminantes con Stop.
        $ErrorActionPreference = 'Continue'
        & $psql -X -w -v ON_ERROR_STOP=1 -h $DbHost -p $DbPort -U $DbUser -d foodstore -f $scriptFile 2>&1 |
            ForEach-Object { $_.ToString() } |
            Out-File -LiteralPath $log -Append -Encoding utf8
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($code -ne 0) { throw "$label falló con código $code" }
    "$(Get-Date -Format o) OK $label" | Add-Content -LiteralPath $log
}

try {
    Invoke-Checked 'health_check' (Join-Path $tp8 'health_check.sql')
    if ((Get-Date).DayOfWeek -eq 'Monday') {
        Invoke-Checked 'maintenance' (Join-Path $tp8 'maintenance.sql')
    } else {
        "$(Get-Date -Format o) maintenance: revisión semanal prevista para lunes" | Add-Content -LiteralPath $log
    }
    # Ejecutar fuera del pipeline: un Out-File exitoso no debe ocultar un fallo del respaldo.
    $backupOutput = & $BackupScript -PgBin $PgBin -DbHost $DbHost -DbPort $DbPort -DbUser $DbUser 2>&1 6>&1
    $backupCode = $LASTEXITCODE
    @($backupOutput) | ForEach-Object { $_.ToString() } | Out-File -LiteralPath $log -Append -Encoding utf8
    if ($backupCode -ne 0) { throw "Respaldo falló con código $backupCode" }
    "$(Get-Date -Format o) OK respaldo" | Add-Content -LiteralPath $log
} catch {
    "$(Get-Date -Format o) ERROR $($_.Exception.Message)" | Add-Content -LiteralPath $log
    throw
}
