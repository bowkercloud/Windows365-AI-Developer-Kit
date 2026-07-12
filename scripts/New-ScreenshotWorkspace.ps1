#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$Model = "phi-4-mini"
)

$root = Split-Path $PSScriptRoot -Parent
$guide = Join-Path $root "docs\Screenshot-Guide.md"
$screenshotFolder = Join-Path $root "results\screenshots"

New-Item -ItemType Directory -Path $screenshotFolder -Force | Out-Null

Write-Host "Preparing a clean screenshot workspace..." -ForegroundColor Cyan
Start-Process explorer.exe $screenshotFolder
Start-Process wt.exe -ArgumentList "pwsh.exe", "-NoExit", "-Command", "foundry service status; foundry cache list"
Start-Sleep -Seconds 2

if (Get-Command code -ErrorAction SilentlyContinue) {
    Start-Process code.exe -ArgumentList $root
}

Start-Process $guide

Write-Host ""
Write-Host "Windows Snipping Tool shortcut: Win + Shift + S" -ForegroundColor Yellow
Write-Host "Save screenshots to: $screenshotFolder" -ForegroundColor Green
Write-Host "Suggested model command: foundry model run $Model" -ForegroundColor White
