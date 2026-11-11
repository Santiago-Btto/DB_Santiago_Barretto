param(
    [string]$Hora = '20:00',
    [ValidateSet('Interactive', 'S4U')][string]$LogonType = 'Interactive'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$taskName = 'FoodStore-BDII-U6-Diario'
$runner = Join-Path $PSScriptRoot 'ejecutar_mantenimiento_u6.ps1'
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) { throw "Falta $runner" }
if ($Hora -notmatch '^([01]\d|2[0-3]):[0-5]\d$') { throw 'Hora inválida (HH:mm)' }
$time = [datetime]::ParseExact($Hora, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture)
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $runner)
$trigger = New-ScheduledTaskTrigger -Daily -At $time
$account = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$principal = New-ScheduledTaskPrincipal -UserId $account -LogonType $LogonType -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Get-ScheduledTask -TaskName $taskName | Select-Object TaskName, State, TaskPath
Get-ScheduledTaskInfo -TaskName $taskName | Select-Object NextRunTime, LastRunTime, LastTaskResult
