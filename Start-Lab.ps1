#requires -Version 7.0
<#
.SYNOPSIS
    Bootstraps the Windows 365 local AI developer lab.

.DESCRIPTION
    Designed for a Windows 365 16 vCPU Cloud PC provisioned from the
    "Image with Developer Configuration (preview)" gallery image.

    The script validates the preinstalled developer tooling, installs
    Microsoft Foundry Local, downloads a local model, performs a smoke
    test, and optionally runs repeatable benchmarks.

.NOTES
    Foundry Local is currently in preview. Commands may change.
#>

[CmdletBinding()]
param(
    [string]$Model = "phi-4-mini",
    [int]$BenchmarkRuns = 3,
    [switch]$SkipModelDownload,
    [switch]$SkipBenchmarks,
    [switch]$OpenScreenshotGuide
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptRoot = Join-Path $Root "scripts"
$ResultRoot = Join-Path $Root "results"

function Write-Stage {
    param([string]$Message)
    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor Cyan
    Write-Host " $Message" -ForegroundColor Cyan
    Write-Host ("=" * 72) -ForegroundColor Cyan
}

Write-Host @"
 __        ___           _                     ____   ____  ____
 \ \      / (_)_ __   __| | _____      _____  |___ \ / ___|| ___|
  \ \ /\ / /| | '_ \ / _` |/ _ \ \ /\ / / __|   __) | |  _ |___ \
   \ V  V / | | | | | (_| | (_) \ V  V /\__ \  / __/| |_| | ___) |
    \_/\_/  |_|_| |_|\__,_|\___/ \_/\_/ |___/ |_____|\____||____/

              Local AI Developer Kit
"@ -ForegroundColor Green

Write-Stage "1. Validate the Developer Configuration gallery image"
& (Join-Path $ScriptRoot "Test-DeveloperImage.ps1") -OutputPath (Join-Path $ResultRoot "inventory")

Write-Stage "2. Install or update Microsoft Foundry Local"
& (Join-Path $ScriptRoot "Install-AITooling.ps1")

if (-not $SkipModelDownload) {
    Write-Stage "3. Download model: $Model"
    & foundry model info $Model
    & foundry model download $Model
}
else {
    Write-Stage "3. Model download skipped"
}

Write-Stage "4. Verify local inference"
& (Join-Path $ScriptRoot "Test-LocalInference.ps1") -Model $Model

if (-not $SkipBenchmarks) {
    Write-Stage "5. Run benchmark"
    & (Join-Path $ScriptRoot "Invoke-Benchmark.ps1") `
        -Model $Model `
        -Runs $BenchmarkRuns `
        -OutputPath (Join-Path $ResultRoot "benchmarks")
}
else {
    Write-Stage "5. Benchmarks skipped"
}

Write-Stage "6. Lab ready"
Write-Host "Results: $ResultRoot" -ForegroundColor Green
Write-Host "Run the interactive model with:" -ForegroundColor Yellow
Write-Host "  foundry model run $Model" -ForegroundColor White
Write-Host ""
Write-Host "Screenshot checklist:" -ForegroundColor Yellow
Write-Host "  docs\Screenshot-Guide.md" -ForegroundColor White

if ($OpenScreenshotGuide) {
    Start-Process (Join-Path $Root "docs\Screenshot-Guide.md")
}
