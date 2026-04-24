#Requires -Version 5.1
<#
.SYNOPSIS
  Registers a daily Windows Scheduled Task that runs scripts\run.ps1.
.PARAMETER Time
  Local time to fire, as HH:mm. Default: 18:03.
.PARAMETER TaskName
  Scheduled task name. Default: ClaudeDailyLog.
#>
param(
    [string]$Time = '18:03',
    [string]$TaskName = 'ClaudeDailyLog'
)

$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $PSScriptRoot
$runScript = Join-Path $projectDir 'scripts\run.ps1'

if (-not (Test-Path $runScript)) {
    Write-Error "run.ps1 not found at $runScript"
    exit 1
}

if ($Time -notmatch '^\d{2}:\d{2}$') {
    Write-Error "Time must be in HH:mm format (got '$Time')."
    exit 1
}

$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$runScript`""

$trigger = New-ScheduledTaskTrigger -Daily -At $Time

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -DontStopOnIdleEnd `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description 'Daily Obsidian activity log via Claude Code' `
    -Force | Out-Null

Write-Host "Scheduled task '$TaskName' registered. Fires daily at $Time local time."
Write-Host "To test now:  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "To remove:    Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
