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

function Invoke-KitNativeCommandInConsole {
    <#
    .SYNOPSIS
        Runs a native command with its output attached directly to the console.

    .DESCRIPTION
        Avoids routing native output through PowerShell's success pipeline.
        This preserves UTF-8 symbols and terminal formatting while allowing a
        caller to return a separate value from the same function.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string[]]$ArgumentList = @(),

        [int[]]$SuccessExitCode = @(0)
    )

    $resolvedCommand = Get-Command $FilePath -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $resolvedCommand) {
        throw "Command was not found on PATH: $FilePath"
    }

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $resolvedCommand.Source
    $startInfo.UseShellExecute = $false

    foreach ($argument in $ArgumentList) {
        $startInfo.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        [void]$process.Start()
        $process.WaitForExit()
    }
    catch {
        throw "Unable to start command '$FilePath': $($_.Exception.Message)"
    }

    if ($process.ExitCode -notin $SuccessExitCode) {
        throw ("Command failed with exit code {0}: {1} {2}" -f $process.ExitCode, $FilePath, ($ArgumentList -join " "))
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

    # Model inspection remains "model info" in both CLI generations. The
    # Foundry Local 0.10.1 release notes listed "model show", but the actual
    # 0.10.2 command help and parser use "model info".
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

function Select-FoundryModel {
    <#
    .SYNOPSIS
        Resolves a supplied model or prompts the user to select one.

    .DESCRIPTION
        Displays chat-capable models when no model was supplied, then asks for
        an alias or model ID. Supplying -Model keeps automation non-interactive.
    #>
    [CmdletBinding()]
    param(
        [string]$Model
    )

    if (-not [string]::IsNullOrWhiteSpace($Model)) {
        return $Model.Trim()
    }

    Write-Host "Available CPU chat model variants:" -ForegroundColor Cyan
    if (Test-FoundryModernCli) {
        Invoke-KitNativeCommandInConsole -FilePath "foundry" -ArgumentList @(
            "model", "list", "--type", "chat", "--device", "cpu", "--variants"
        )
    }
    else {
        Invoke-KitNativeCommandInConsole -FilePath "foundry" -ArgumentList @(
            "model", "list", "--filter", "device=CPU"
        )
    }

    do {
        $selection = Read-Host "Enter a model alias or ID"
    } while ([string]::IsNullOrWhiteSpace($selection))

    return $selection.Trim()
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
