#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectDir 'config.json'
$promptPath = Join-Path $projectDir 'prompt.md'

if (-not (Test-Path $configPath)) {
    Write-Error "config.json not found at $configPath - copy config.example.json and edit it."
    exit 1
}

$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) {
    Write-Error "claude CLI not found on PATH."
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json

function Expand-UserPath([string]$p) {
    if ($p -match '^~') { return $p -replace '^~', $env:USERPROFILE }
    return $p
}

$candidatePaths = @()
$candidatePaths += Expand-UserPath $config.vault_path
$candidatePaths += Expand-UserPath $config.transcript_root
foreach ($d in $config.project_dirs) { $candidatePaths += Expand-UserPath $d }

$addDirArgs = @()
foreach ($p in $candidatePaths) {
    if ($p -and (Test-Path $p)) {
        $addDirArgs += '--add-dir'
        $addDirArgs += $p
    }
}

Set-Location $projectDir
Get-Content $promptPath -Raw | & claude --print --permission-mode acceptEdits @addDirArgs
