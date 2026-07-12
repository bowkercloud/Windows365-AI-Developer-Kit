#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$Model = "phi-4-mini",
    [string]$Prompt = "In two concise sentences, explain why a developer might run a language model locally on a Windows 365 Cloud PC."
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command foundry -ErrorAction SilentlyContinue)) {
    throw "Foundry Local is not installed or not available in PATH."
}

Write-Host "Foundry Local service:" -ForegroundColor Cyan
& foundry service status

Write-Host ""
Write-Host "Model information:" -ForegroundColor Cyan
& foundry model info $Model

Write-Host ""
Write-Host "Loading model..." -ForegroundColor Cyan
& foundry model load $Model

# The CLI's interactive mode is the most stable smoke test while the product is in preview.
# Pipe a prompt followed by /exit so the test remains repeatable.
Write-Host ""
Write-Host "Running smoke-test prompt..." -ForegroundColor Cyan
$inputText = "$Prompt`n/exit`n"
$response = $inputText | & foundry model run $Model 2>&1

$response | ForEach-Object { Write-Host $_ }

if (-not $response) {
    throw "No output was returned from the model."
}

Write-Host ""
Write-Host "Local inference smoke test completed." -ForegroundColor Green
