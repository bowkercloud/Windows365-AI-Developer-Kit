# Architecture

The Windows 365 AI Developer Kit is a staged PowerShell toolkit. The design keeps the public install command small, then delegates each lab activity to a focused script.

## Flow

```text
irm https://bowker.cloud/w365ai | iex
        |
        v
Install.ps1
        |
        v
Start-Lab.ps1
        |
        v
scripts\Common.ps1
        |
        +--> Test-DeveloperImage.ps1
        +--> Install-AITooling.ps1
        +--> foundry model download
        +--> Test-LocalInference.ps1
        +--> Invoke-Benchmark.ps1
        +--> New-ScreenshotWorkspace.ps1
        |
        v
results\
```

## Bootstrapper

`Install.ps1` is the remote entry point used by:

```powershell
irm https://bowker.cloud/w365ai | iex
```

Responsibilities:

- Validate PowerShell 7.
- Validate Git.
- Clone or update the repository.
- Unblock downloaded files.
- Launch `Start-Lab.ps1` with the selected parameters.

The bootstrapper should stay thin. It should not contain benchmarking, Foundry Local or sample-app logic.

## Orchestrator

`Start-Lab.ps1` coordinates the lab stages and owns the user-facing sequence.

Responsibilities:

- Print the toolkit banner.
- Run prerequisite inventory.
- Install or update Foundry Local.
- Download the selected model unless skipped.
- Run local inference validation.
- Run benchmarks unless skipped.
- Point the user to generated results and screenshot guidance.

## Shared Helpers

`scripts\Common.ps1` contains reusable helpers for:

- Standard banner and stage output.
- Success and warning formatting.
- Command availability checks.
- Native command execution with exit-code validation.

Shared behaviour should be added here only when at least two scripts need it.

## Stage Scripts

Each stage script should be independently runnable:

- `Test-DeveloperImage.ps1` records Cloud PC hardware, Windows version, WSL status, VS Code extensions and expected developer tools.
- `Install-AITooling.ps1` installs or updates Microsoft Foundry Local through WinGet.
- `Test-LocalInference.ps1` runs a Foundry Local smoke test.
- `Invoke-Benchmark.ps1` runs repeatable end-to-end prompt benchmarks and writes CSV, JSON, Markdown and telemetry output.
- `New-ScreenshotWorkspace.ps1` opens a safe workspace for manual screenshot capture.

## Results

Generated files live under `results` and should not be committed except for `.gitkeep` placeholders.

```text
results
├── benchmarks
├── inventory
└── screenshots
```

## Future Direction

The toolkit can evolve toward:

- A PowerShell module.
- Pester tests.
- GitHub Actions.
- HTML benchmark reports.
- Azure AI Foundry comparisons.
- Sample AI applications.
- GPU benchmarking.

The staged layout should remain stable even as implementation details move into a module.
