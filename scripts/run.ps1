#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectDir 'config.json'
$promptPath = Join-Path $projectDir 'prompt.md'

if (-not (Test-Path $configPath)) {
    Write-Error "config.json not found at $configPath — copy config.example.json and edit it."
    exit 1
}

$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) {
    Write-Error "claude CLI not found on PATH."
    exit 1
}

Set-Location $projectDir
Get-Content $promptPath -Raw | & claude --print
