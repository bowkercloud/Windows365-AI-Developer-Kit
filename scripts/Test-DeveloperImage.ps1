#requires -Version 7.0
<#
.SYNOPSIS
    Captures Windows 365 developer image inventory and prerequisite status.

.DESCRIPTION
    Records system details, expected developer tools, WSL status and VS Code
    extensions for a Cloud PC provisioned from the Developer Configuration
    gallery image.

.PARAMETER OutputPath
    Folder where inventory files should be written.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path (Split-Path $PSScriptRoot -Parent) "results\inventory")
)

$ErrorActionPreference = "Continue"
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot "Common.ps1")

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

function Get-ToolResult {
    <#
    .SYNOPSIS
        Returns command availability and version details for one tool.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Command,

        [string[]]$Arguments = @("--version"),

        [switch]$Optional
    )

    $resolved = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $resolved) {
        return [pscustomobject]@{
            Tool = $Name
            Status = if ($Optional) { "Optional/Missing" } else { "Missing" }
            Version = ""
            Path = ""
        }
    }

    try {
        $version = (& $Command @Arguments 2>&1 | Select-Object -First 1).ToString().Trim()
    }
    catch {
        $version = "Installed; version query failed: $($_.Exception.Message)"
    }

    [pscustomobject]@{
        Tool = $Name
        Status = "Present"
        Version = $version
        Path = $resolved.Source
    }
}

function Invoke-InventoryCommand {
    <#
    .SYNOPSIS
        Runs an inventory command and returns text output without failing the stage.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string[]]$Arguments = @()
    )

    if (-not (Test-KitCommand -Command $Command)) {
        return @("$Command was not found on PATH.")
    }

    try {
        return & $Command @Arguments 2>&1
    }
    catch {
        return @("Command failed: $($_.Exception.Message)")
    }
}

$tools = @(
    Get-ToolResult -Name "PowerShell 7" -Command "pwsh" -Arguments @("-NoLogo", "-Command", '$PSVersionTable.PSVersion.ToString()')
    Get-ToolResult -Name "Visual Studio Code" -Command "code"
    Get-ToolResult -Name "WSL" -Command "wsl.exe" -Arguments @("--version")
    Get-ToolResult -Name "Python" -Command "python"
    Get-ToolResult -Name "Node.js" -Command "node"
    Get-ToolResult -Name "npm" -Command "npm"
    Get-ToolResult -Name "Git" -Command "git"
    Get-ToolResult -Name "GitHub CLI" -Command "gh"
    Get-ToolResult -Name "Azure CLI" -Command "az"
    Get-ToolResult -Name ".NET SDK" -Command "dotnet"
    Get-ToolResult -Name "UV" -Command "uv" -Optional
    Get-ToolResult -Name "WinApp CLI" -Command "winapp" -Optional
    Get-ToolResult -Name "GitHub Copilot CLI" -Command "copilot" -Optional
)

$computer = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

$system = [pscustomobject]@{
    CapturedAt = (Get-Date).ToString("o")
    ComputerName = $env:COMPUTERNAME
    Manufacturer = $computer.Manufacturer
    Model = $computer.Model
    LogicalProcessors = $computer.NumberOfLogicalProcessors
    MemoryGB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
    Processor = $cpu.Name.Trim()
    Windows = $os.Caption
    WindowsVersion = $os.Version
    WindowsBuild = $os.BuildNumber
    OSArchitecture = $os.OSArchitecture
    CDriveSizeGB = [math]::Round($disk.Size / 1GB, 2)
    CDriveFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
}

$wslOutput = Invoke-InventoryCommand -Command "wsl.exe" -Arguments @("--status")
$wslList = Invoke-InventoryCommand -Command "wsl.exe" -Arguments @("--list", "--verbose")
$extensions = if (Get-Command code -ErrorAction SilentlyContinue) {
    & code --list-extensions 2>&1
} else { @() }

$system | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $OutputPath "System.json")
$tools | Export-Csv (Join-Path $OutputPath "DeveloperTools.csv") -NoTypeInformation
$tools | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $OutputPath "DeveloperTools.json")
$wslOutput | Set-Content (Join-Path $OutputPath "WSL-Status.txt")
$wslList | Set-Content (Join-Path $OutputPath "WSL-Distributions.txt")
$extensions | Set-Content (Join-Path $OutputPath "VSCode-Extensions.txt")
systeminfo.exe | Set-Content (Join-Path $OutputPath "SystemInfo.txt")

Write-Host ""
Write-Host "Cloud PC inventory" -ForegroundColor Cyan
$system | Format-List
Write-Host "Developer tool validation" -ForegroundColor Cyan
$tools | Format-Table -AutoSize

$missingRequired = $tools | Where-Object Status -eq "Missing"
if ($missingRequired) {
    Write-Warning "One or more expected developer tools are missing. Review DeveloperTools.csv."
}
else {
    Write-KitSuccess "Expected core developer tooling is present"
}
