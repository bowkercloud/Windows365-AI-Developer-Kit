#requires -Version 7.0
<#
.SYNOPSIS
    Shared helper functions for the Windows 365 AI Developer Kit.

.DESCRIPTION
    Provides consistent console output, command discovery and native command
    invocation behaviour for the bootstrapper and lab scripts.
#>

Set-StrictMode -Version Latest
$script:FoundryModernCli = $null

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

function Test-FoundryModernCli {
    <#
    .SYNOPSIS
        Detects the Foundry Local 0.10.x command surface.

    .DESCRIPTION
        Foundry Local 0.10 replaced the earlier service-based CLI. Command
        probing is used instead of parsing a preview version string so this
        continues to work if Microsoft changes the version format.
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-KitCommand -Command "foundry")) {
        throw "Foundry Local is not installed or not available in PATH."
    }

    if ($null -eq $script:FoundryModernCli) {
        & foundry server --help *> $null
        $script:FoundryModernCli = ($LASTEXITCODE -eq 0)
    }

    return $script:FoundryModernCli
}

function Get-FoundryStatusArguments {
    <#
    .SYNOPSIS
        Returns arguments for displaying Foundry Local status.
    #>
    [CmdletBinding()]
    param()

    if (Test-FoundryModernCli) {
        return @("status")
    }

    return @("service", "status")
}

function Get-FoundryRestartArguments {
    <#
    .SYNOPSIS
        Returns arguments for restarting Foundry Local.
    #>
    [CmdletBinding()]
    param()

    if (Test-FoundryModernCli) {
        return @("server", "restart")
    }

    return @("service", "restart")
}

function Get-FoundryModelInfoArguments {
    <#
    .SYNOPSIS
        Returns arguments for displaying information about a model.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Model
    )

    if (Test-FoundryModernCli) {
        return @("model", "show", $Model)
    }

    return @("model", "info", $Model)
}

function Get-FoundryRunArguments {
    <#
    .SYNOPSIS
        Returns arguments for running an interactive model session.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Model
    )

    if (Test-FoundryModernCli) {
        return @("run", $Model)
    }

    return @("model", "run", $Model)
}

function Format-FoundryCommand {
    <#
    .SYNOPSIS
        Formats a Foundry argument list for user-facing instructions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ArgumentList
    )

    return "foundry $($ArgumentList -join ' ')"
}
