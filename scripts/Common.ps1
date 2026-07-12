#requires -Version 7.0
<#
.SYNOPSIS
    Shared helper functions for the Windows 365 AI Developer Kit.

.DESCRIPTION
    Provides consistent console output, command discovery and native command
    invocation behaviour for the bootstrapper and lab scripts.
#>

Set-StrictMode -Version Latest

function Write-KitHeader {
    <#
    .SYNOPSIS
        Writes the standard toolkit banner.
    #>
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host " Windows 365 AI Developer Kit" -ForegroundColor Cyan
    Write-Host " Community toolkit by Dan Bowker" -ForegroundColor Cyan
    Write-Host " https://bowker.cloud" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
}

function Write-KitStage {
    <#
    .SYNOPSIS
        Writes a formatted stage heading.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor Cyan
    Write-Host " $Message" -ForegroundColor Cyan
    Write-Host ("=" * 72) -ForegroundColor Cyan
}

function Write-KitSuccess {
    <#
    .SYNOPSIS
        Writes a standard success line.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host ("✓ {0}" -f $Message) -ForegroundColor Green
}

function Write-KitWarning {
    <#
    .SYNOPSIS
        Writes a standard warning line.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Warning $Message
}

function Test-KitCommand {
    <#
    .SYNOPSIS
        Tests whether a command is available on PATH.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Invoke-KitNativeCommand {
    <#
    .SYNOPSIS
        Runs a native command and throws when it returns a non-zero exit code.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string[]]$ArgumentList = @(),

        [int[]]$SuccessExitCode = @(0)
    )

    Write-Verbose ("Running: {0} {1}" -f $FilePath, ($ArgumentList -join " "))
    & $FilePath @ArgumentList
    $exitCode = $LASTEXITCODE

    if ($null -ne $exitCode -and $exitCode -notin $SuccessExitCode) {
        throw ("Command failed with exit code {0}: {1} {2}" -f $exitCode, $FilePath, ($ArgumentList -join " "))
    }
}
