#requires -Version 7.0
<#
.SYNOPSIS
    Runs a repeatable end-to-end Foundry Local CLI benchmark.

.DESCRIPTION
    This measures elapsed time for a complete prompt/response interaction.
    It is intentionally an experience benchmark rather than a scientific
    tokens-per-second benchmark. Foundry Local is in preview and its CLI/API
    surface may change.

    CPU and available memory are sampled while each run executes.
#>
[CmdletBinding()]
param(
    [string]$Model = "phi-4-mini",
    [ValidateRange(1, 100)]
    [int]$Runs = 3,
    [string]$Prompt = "Provide five concise practical considerations for running local language models on a Windows 365 Cloud PC.",
    [string]$OutputPath = (Join-Path (Split-Path $PSScriptRoot -Parent) "results\benchmarks")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot "Common.ps1")

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

if (-not (Get-Command foundry -ErrorAction SilentlyContinue)) {
    throw "Foundry Local is not installed or not available in PATH."
}

Invoke-KitNativeCommand -FilePath "foundry" -ArgumentList @("model", "load", $Model)

$results = for ($run = 1; $run -le $Runs; $run++) {
    Write-Host "Benchmark run $run of $Runs..." -ForegroundColor Cyan

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "foundry"
    $psi.ArgumentList.Add("model")
    $psi.ArgumentList.Add("run")
    $psi.ArgumentList.Add($Model)
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $psi

    $samples = [System.Collections.Generic.List[object]]::new()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    [void]$process.Start()
    $process.StandardInput.WriteLine($Prompt)
    $process.StandardInput.WriteLine("/exit")
    $process.StandardInput.Close()

    while (-not $process.HasExited) {
        $os = Get-CimInstance Win32_OperatingSystem
        $cpuValue = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples.CookedValue
        $samples.Add([pscustomobject]@{
            Timestamp = Get-Date
            CpuPercent = [math]::Round($cpuValue, 2)
            AvailableMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        })
        Start-Sleep -Milliseconds 750
    }

    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $stopwatch.Stop()

    $outputFile = Join-Path $OutputPath ("Run-{0:D2}-Output.txt" -f $run)
    $stdout | Set-Content $outputFile
    if ($stderr) {
        $stderr | Add-Content $outputFile
    }

    $sampleFile = Join-Path $OutputPath ("Run-{0:D2}-Telemetry.csv" -f $run)
    $samples | Export-Csv $sampleFile -NoTypeInformation

    [pscustomobject]@{
        Run = $run
        Model = $Model
        ElapsedSeconds = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
        AverageCpuPercent = if ($samples.Count) { [math]::Round(($samples.CpuPercent | Measure-Object -Average).Average, 2) } else { $null }
        PeakCpuPercent = if ($samples.Count) { [math]::Round(($samples.CpuPercent | Measure-Object -Maximum).Maximum, 2) } else { $null }
        LowestAvailableMemoryGB = if ($samples.Count) { [math]::Round(($samples.AvailableMemoryGB | Measure-Object -Minimum).Minimum, 2) } else { $null }
        ExitCode = $process.ExitCode
        OutputFile = $outputFile
    }

    Start-Sleep -Seconds 2
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvPath = Join-Path $OutputPath "Benchmark-$timestamp.csv"
$jsonPath = Join-Path $OutputPath "Benchmark-$timestamp.json"
$mdPath = Join-Path $OutputPath "Benchmark-$timestamp.md"

$results | Export-Csv $csvPath -NoTypeInformation
$results | ConvertTo-Json -Depth 4 | Set-Content $jsonPath

$avgTime = [math]::Round(($results.ElapsedSeconds | Measure-Object -Average).Average, 2)
$avgCpu = [math]::Round(($results.AverageCpuPercent | Measure-Object -Average).Average, 2)

$markdown = @"
# Foundry Local benchmark

- **Captured:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Cloud PC:** $env:COMPUTERNAME
- **Model:** $Model
- **Runs:** $Runs
- **Average elapsed time:** $avgTime seconds
- **Average sampled CPU:** $avgCpu%

| Run | Elapsed (s) | Avg CPU (%) | Peak CPU (%) | Lowest available memory (GB) | Exit code |
|---:|---:|---:|---:|---:|---:|
$(
    ($results | ForEach-Object {
        "| $($_.Run) | $($_.ElapsedSeconds) | $($_.AverageCpuPercent) | $($_.PeakCpuPercent) | $($_.LowestAvailableMemoryGB) | $($_.ExitCode) |"
    }) -join "`n"
)
"@

$markdown | Set-Content $mdPath

Write-Host ""
$results | Format-Table -AutoSize
Write-Host "Benchmark CSV: $csvPath" -ForegroundColor Green
Write-Host "Blog-ready Markdown: $mdPath" -ForegroundColor Green
