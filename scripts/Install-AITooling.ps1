#requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$ForceReinstall
)

$ErrorActionPreference = "Stop"

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "WinGet is required but was not found."
}

$foundry = Get-Command foundry -ErrorAction SilentlyContinue
if ($foundry -and -not $ForceReinstall) {
    Write-Host "Foundry Local already installed. Checking for updates..." -ForegroundColor Yellow
    & winget upgrade --id Microsoft.FoundryLocal --exact `
        --accept-package-agreements --accept-source-agreements
}
else {
    if ($ForceReinstall -and $foundry) {
        & winget uninstall --id Microsoft.FoundryLocal --exact --silent
    }

    Write-Host "Installing Microsoft Foundry Local..." -ForegroundColor Cyan
    & winget install --id Microsoft.FoundryLocal --exact `
        --accept-package-agreements --accept-source-agreements
}

Refresh-Path

if (-not (Get-Command foundry -ErrorAction SilentlyContinue)) {
    Write-Warning "Foundry was installed but is not available in this process PATH."
    Write-Warning "Close and reopen PowerShell, then rerun Start-Lab.ps1."
    exit 3010
}

& foundry --version

try {
    & foundry service status
}
catch {
    Write-Warning "Foundry Local service did not respond. Restarting it."
    & foundry service restart
    Start-Sleep -Seconds 3
    & foundry service status
}
