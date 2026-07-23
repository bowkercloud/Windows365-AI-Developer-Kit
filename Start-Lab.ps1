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
    [ValidateRange(1, 100)]
    [int]$BenchmarkRuns = 3,
    [switch]$SkipModelDownload,
    [switch]$SkipBenchmarks,
    [switch]$OpenScreenshotGuide
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"
Set-StrictMode -Version Latest

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptRoot = Join-Path $Root "scripts"
$ResultRoot = Join-Path $Root "results"

. (Join-Path $ScriptRoot "Common.ps1")

try {
    Write-KitHeader

    Write-KitStage "1. Validate the Developer Configuration gallery image"
    & (Join-Path $ScriptRoot "Test-DeveloperImage.ps1") -OutputPath (Join-Path $ResultRoot "inventory")

    Write-KitStage "2. Install or update Microsoft Foundry Local"
    & (Join-Path $ScriptRoot "Install-AITooling.ps1")

    if (-not $SkipModelDownload) {
        Write-KitStage "3. Download model: $Model"
        Invoke-KitNativeCommand -FilePath "foundry" -ArgumentList (Get-FoundryModelInfoArguments -Model $Model)
        Invoke-KitNativeCommand -FilePath "foundry" -ArgumentList @("model", "download", $Model)
    }
    else {
        Write-KitStage "3. Model download skipped"
    }

    Write-KitStage "4. Verify local inference"
    & (Join-Path $ScriptRoot "Test-LocalInference.ps1") -Model $Model

    if (-not $SkipBenchmarks) {
        Write-KitStage "5. Run benchmark"
        & (Join-Path $ScriptRoot "Invoke-Benchmark.ps1") `
            -Model $Model `
            -Runs $BenchmarkRuns `
            -OutputPath (Join-Path $ResultRoot "benchmarks")
    }
    else {
        Write-KitStage "5. Benchmarks skipped"
    }

    Write-KitStage "6. Lab ready"
    Write-KitSuccess "Lab ready"
    Write-Host "Results: $ResultRoot" -ForegroundColor Green
    Write-Host "Run the interactive model with:" -ForegroundColor Yellow
    Write-Host ("  {0}" -f (Format-FoundryCommand -ArgumentList (Get-FoundryRunArguments -Model $Model))) -ForegroundColor White
    Write-Host ""
    Write-Host "Screenshot checklist:" -ForegroundColor Yellow
    Write-Host "  docs\Screenshot-Guide.md" -ForegroundColor White

    if ($OpenScreenshotGuide) {
        Start-Process (Join-Path $Root "docs\Screenshot-Guide.md")
    }

    exit 0
}
catch {
    Write-Error $_
    exit 1
}
