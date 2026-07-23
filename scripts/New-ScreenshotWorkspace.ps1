#requires -Version 7.0
<#
.SYNOPSIS
    Opens a workspace for capturing blog screenshots.

.DESCRIPTION
    Creates the screenshot results folder and opens the key local windows used
    when documenting a Windows 365 AI Developer Kit run.

.PARAMETER Model
    Model name shown in the suggested interactive command.
#>
[CmdletBinding()]
param(
    [string]$Model = "phi-4-mini"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Split-Path $PSScriptRoot -Parent
$guide = Join-Path $root "docs\Screenshot-Guide.md"
$screenshotFolder = Join-Path $root "results\screenshots"

New-Item -ItemType Directory -Path $screenshotFolder -Force | Out-Null

Write-Host "Preparing a clean screenshot workspace..." -ForegroundColor Cyan
$statusCommand = Format-FoundryCommand -ArgumentList (Get-FoundryStatusArguments)
$runCommand = Format-FoundryCommand -ArgumentList (Get-FoundryRunArguments -Model $Model)
Start-Process explorer.exe $screenshotFolder
Start-Process wt.exe -ArgumentList "pwsh.exe", "-NoExit", "-Command", "$statusCommand; foundry cache list"
Start-Sleep -Seconds 2

if (Get-Command code -ErrorAction SilentlyContinue) {
    Start-Process code.exe -ArgumentList $root
}

Start-Process $guide

Write-Host ""
Write-Host "Windows Snipping Tool shortcut: Win + Shift + S" -ForegroundColor Yellow
Write-Host "Save screenshots to: $screenshotFolder" -ForegroundColor Green
Write-Host "Suggested model command: $runCommand" -ForegroundColor White
