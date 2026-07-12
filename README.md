# Windows 365 AI Developer Kit

A practical lab for testing local language models on a Windows 365 Cloud PC provisioned from the **Image with Developer Configuration (preview)** gallery image.

## Tested design target

- Windows 365 Enterprise
- 16 vCPU / 64 GB Cloud PC
- Developer Configuration gallery image
- Microsoft Foundry Local
- `phi-4-mini`
- CPU-based local inference

## What this project does

1. Validates the developer tools supplied in the gallery image.
2. Records the Cloud PC hardware and Windows configuration.
3. Validates WSL and Ubuntu.
4. Installs or updates Microsoft Foundry Local.
5. Downloads the selected language model.
6. Performs a repeatable local-inference smoke test.
7. Runs a basic end-to-end benchmark.
8. Produces CSV, JSON, Markdown and telemetry output for a blog.
9. Provides a safe, repeatable screenshot checklist.

## Run

Open **PowerShell 7 as Administrator**, change into the repository folder, and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Start-Lab.ps1 -Model phi-4-mini -BenchmarkRuns 3 -OpenScreenshotGuide
```

Foundry Local installation may require you to close and reopen PowerShell so its command is added to `PATH`. If the script returns exit code `3010`, reopen PowerShell and run it again.

## Run individual stages

```powershell
.\scripts\Test-DeveloperImage.ps1
.\scripts\Install-AITooling.ps1
foundry model download phi-4-mini
.\scripts\Test-LocalInference.ps1 -Model phi-4-mini
.\scripts\Invoke-Benchmark.ps1 -Model phi-4-mini -Runs 3
.\scripts\New-ScreenshotWorkspace.ps1 -Model phi-4-mini
```

## Results

Generated output is written beneath:

```text
results
├── benchmarks
├── inventory
└── screenshots
```

## Important

This is a first working lab version built against preview tooling. Review the generated results and commands before publishing. The benchmark intentionally measures the practical end-to-end experience rather than claiming scientific model performance.
