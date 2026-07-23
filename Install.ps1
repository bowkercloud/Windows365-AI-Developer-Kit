<#
.SYNOPSIS
    Installs and launches the Windows 365 AI Developer Kit.

.DESCRIPTION
    Bootstrapper designed for:

        irm https://bowker.cloud/w365ai | iex

    The script validates core prerequisites, clones or updates the GitHub
    repository, unblocks downloaded files and launches Start-Lab.ps1.

.PARAMETER RepositoryUrl
    Git repository URL to clone. Defaults to the public toolkit repository.

.PARAMETER InstallPath
    Local folder where the repository should be cloned or updated.

.PARAMETER Branch
    Branch to check out when cloning or updating.

.PARAMETER Model
    Foundry Local model alias or identifier to test. When omitted, the user
    selects a model after Foundry Local is ready.

.PARAMETER BenchmarkRuns
    Number of benchmark runs to perform.

.PARAMETER SkipModelDownload
    Skips model download and assumes the model is already available.

.PARAMETER SkipBenchmarks
    Skips benchmark execution.

.EXAMPLE
    irm https://bowker.cloud/w365ai | iex

.EXAMPLE
    .\Install.ps1 -InstallPath C:\Dev\Windows365-AI-Developer-Kit -BenchmarkRuns 5
#>

[CmdletBinding()]
param(
    [string]$RepositoryUrl = "https://github.com/bowkercloud/Windows365-AI-Developer-Kit.git",
    [string]$InstallPath = (Join-Path ([Environment]::GetFolderPath("UserProfile")) "source\repos\Windows365-AI-Developer-Kit"),
    [string]$Branch = "main",
    [string]$Model,
    [ValidateRange(1, 100)]
    [int]$BenchmarkRuns = 3,
    [switch]$SkipModelDownload,
    [switch]$SkipBenchmarks
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-BootstrapHeader {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host " Windows 365 AI Developer Kit" -ForegroundColor Cyan
    Write-Host " Community toolkit by Dan Bowker" -ForegroundColor Cyan
    Write-Host " https://bowker.cloud" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
}

function Write-BootstrapSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host ("✓ {0}" -f $Message) -ForegroundColor Green
}

function Test-BootstrapCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Invoke-BootstrapGit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ArgumentList,

        [string]$WorkingDirectory
    )

    $previousLocation = Get-Location
    try {
        if ($WorkingDirectory) {
            Set-Location -LiteralPath $WorkingDirectory
        }

        Write-Verbose ("git {0}" -f ($ArgumentList -join " "))
        & git @ArgumentList
        if ($LASTEXITCODE -ne 0) {
            throw ("Git command failed with exit code {0}: git {1}" -f $LASTEXITCODE, ($ArgumentList -join " "))
        }
    }
    finally {
        Set-Location -LiteralPath $previousLocation
    }
}

function Test-GitRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    Test-Path -LiteralPath (Join-Path $Path ".git")
}

try {
    Write-BootstrapHeader

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "PowerShell 7 or later is required. Open PowerShell 7 and run the installer again."
    }
    Write-BootstrapSuccess ("PowerShell {0}" -f $PSVersionTable.PSVersion)

    if (-not (Test-BootstrapCommand -Command "git")) {
        throw "Git is required but was not found on PATH. Use the Windows 365 Developer Configuration image or install Git, then retry."
    }
    Write-BootstrapSuccess "Git"

    $parentPath = Split-Path -Parent $InstallPath
    if (-not (Test-Path -LiteralPath $parentPath)) {
        New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
    }

    if (Test-GitRepository -Path $InstallPath) {
        Write-Host "Updating repository: $InstallPath" -ForegroundColor Cyan
        Invoke-BootstrapGit -WorkingDirectory $InstallPath -ArgumentList @("fetch", "--prune", "origin")
        Invoke-BootstrapGit -WorkingDirectory $InstallPath -ArgumentList @("checkout", $Branch)
        Invoke-BootstrapGit -WorkingDirectory $InstallPath -ArgumentList @("pull", "--ff-only", "origin", $Branch)
    }
    elseif (Test-Path -LiteralPath $InstallPath) {
        throw "InstallPath exists but is not a Git repository: $InstallPath"
    }
    else {
        Write-Host "Cloning repository to: $InstallPath" -ForegroundColor Cyan
        Invoke-BootstrapGit -ArgumentList @("clone", "--branch", $Branch, $RepositoryUrl, $InstallPath)
    }

    Write-BootstrapSuccess "Repository ready"

    Write-Host "Unblocking downloaded files..." -ForegroundColor Cyan
    Get-ChildItem -LiteralPath $InstallPath -Recurse -File | Unblock-File -ErrorAction SilentlyContinue
    Write-BootstrapSuccess "Files unblocked"

    $startLabPath = Join-Path $InstallPath "Start-Lab.ps1"
    if (-not (Test-Path -LiteralPath $startLabPath)) {
        throw "Start-Lab.ps1 was not found at $startLabPath"
    }

    Write-Host "Launching lab..." -ForegroundColor Cyan
    $labArguments = @{ BenchmarkRuns = $BenchmarkRuns }
    if (-not [string]::IsNullOrWhiteSpace($Model)) { $labArguments.Model = $Model }
    if ($SkipModelDownload) { $labArguments.SkipModelDownload = $true }
    if ($SkipBenchmarks) { $labArguments.SkipBenchmarks = $true }

    & $startLabPath @labArguments
    exit $LASTEXITCODE
}
catch {
    Write-Error $_
    exit 1
}
