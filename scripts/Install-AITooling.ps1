#requires -Version 7.0
<#
.SYNOPSIS
    Installs or updates Microsoft Foundry Local.

.DESCRIPTION
    Uses WinGet to install Microsoft Foundry Local when it is missing, or to
    upgrade it when it is already present. If Foundry is installed but the
    current shell cannot see it on PATH, the script exits with 3010 so the
    caller can prompt the user to reopen PowerShell and retry.

.PARAMETER ForceReinstall
    Uninstalls and reinstalls Microsoft Foundry Local.
#>
[CmdletBinding()]
param(
    [switch]$ForceReinstall
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot "Common.ps1")

function Update-ProcessPath {
    <#
    .SYNOPSIS
        Refreshes the current process PATH from machine and user scopes.
    #>
    [CmdletBinding()]
    param()

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
    Invoke-KitNativeCommand -FilePath "winget" -ArgumentList @(
        "upgrade",
        "--id", "Microsoft.FoundryLocal",
        "--exact",
        "--accept-package-agreements",
        "--accept-source-agreements"
    ) -SuccessExitCode @(0, -1978335189)
}
else {
    if ($ForceReinstall -and $foundry) {
        Invoke-KitNativeCommand -FilePath "winget" -ArgumentList @(
            "uninstall",
            "--id", "Microsoft.FoundryLocal",
            "--exact",
            "--silent"
        )
    }

    Write-Host "Installing Microsoft Foundry Local..." -ForegroundColor Cyan
    Invoke-KitNativeCommand -FilePath "winget" -ArgumentList @(
        "install",
        "--id", "Microsoft.FoundryLocal",
        "--exact",
        "--accept-package-agreements",
        "--accept-source-agreements"
    )
}

Update-ProcessPath

if (-not (Get-Command foundry -ErrorAction SilentlyContinue)) {
    Write-Warning "Foundry was installed but is not available in this process PATH."
    Write-Warning "Close and reopen PowerShell, then rerun Start-Lab.ps1."
    exit 3010
}

Invoke-KitNativeCommand -FilePath "foundry" -ArgumentList @("--version")

try {
    Invoke-KitNativeCommand -FilePath "foundry" -ArgumentList @("service", "status")
}
catch {
    Write-Warning "Foundry Local service did not respond. Restarting it."
    Invoke-KitNativeCommand -FilePath "foundry" -ArgumentList @("service", "restart")
    Start-Sleep -Seconds 3
    Invoke-KitNativeCommand -FilePath "foundry" -ArgumentList @("service", "status")
}
