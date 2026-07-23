#requires -Version 7.0
<#
.SYNOPSIS
    Runs a Foundry Local smoke test for a selected model.

.DESCRIPTION
    Verifies Foundry Local service status, inspects and loads the requested
    model, then sends a short repeatable prompt.

.PARAMETER Model
    Foundry Local model alias or identifier.

.PARAMETER Prompt
    Prompt text used for the smoke test.
#>
[CmdletBinding()]
param(
    [string]$Model,
    [string]$Prompt = "In two concise sentences, explain why a developer might run a language model locally on a Windows 365 Cloud PC."
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot "Common.ps1")

if (-not (Get-Command foundry -ErrorAction SilentlyContinue)) {
    throw "Foundry Local is not installed or not available in PATH."
}

$Model = Select-FoundryModel -Model $Model

Write-Host "Foundry Local service:" -ForegroundColor Cyan
Invoke-KitNativeCommand -FilePath "foundry" -ArgumentList (Get-FoundryStatusArguments)

Write-Host ""
Write-Host "Model information:" -ForegroundColor Cyan
Invoke-KitNativeCommand -FilePath "foundry" -ArgumentList (Get-FoundryModelInfoArguments -Model $Model)

Write-Host ""
Write-Host "Loading model..." -ForegroundColor Cyan
Invoke-KitNativeCommand -FilePath "foundry" -ArgumentList @("model", "load", $Model)

Write-Host ""
Write-Host "Running smoke-test prompt..." -ForegroundColor Cyan
if (Test-FoundryModernCli) {
    # The stateless command avoids interactive terminal control sequences in
    # captured output on Foundry Local 0.10 and later.
    $response = & foundry complete $Model $Prompt 2>&1
}
else {
    $inputText = "$Prompt`n/exit`n"
    $runArguments = Get-FoundryRunArguments -Model $Model
    $response = $inputText | & foundry @runArguments 2>&1
}
if ($LASTEXITCODE -ne 0) {
    throw "Foundry Local smoke test failed with exit code $LASTEXITCODE."
}

$response | ForEach-Object { Write-Host $_ }

if (-not $response) {
    throw "No output was returned from the model."
}

Write-Host ""
Write-Host "Local inference smoke test completed." -ForegroundColor Green
