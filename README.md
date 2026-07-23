# Windows 365 AI Developer Kit

Community toolkit by Daniel Bowker for building, validating and benchmarking local AI developer environments on Windows 365 Cloud PCs.

The toolkit focuses first on CPU-based local language models with Microsoft
Foundry Local, then expands toward Azure AI Foundry comparisons, reporting,
sample apps and GPU benchmarking.

## Quick Start

Open **PowerShell 7 as Administrator** and run:

```powershell
irm https://bowker.cloud/w365ai | iex
```

The short URL redirects to:

```text
https://raw.githubusercontent.com/bowkercloud/Windows365-AI-Developer-Kit/main/Install.ps1
```

`Install.ps1` validates PowerShell and Git, clones or updates this repository, unblocks downloaded files and launches `Start-Lab.ps1`.

## Tested Design Target

- Windows 365 Enterprise
- Windows 365 Flex Dedicated
- Image with Developer Configuration (preview)
- 16 vCPU / 64 GB Cloud PC
- PowerShell 7
- Microsoft Foundry Local
- User-selected Foundry Local model
- CPU-based local inference

The Developer Configuration image already includes tools such as Git, PowerShell 7, Python, Node.js, VS Code, WSL Ubuntu and Azure CLI. The toolkit detects and uses those components rather than reinstalling them.

## What The Toolkit Does

1. Validates developer tools supplied in the gallery image.
2. Records Cloud PC hardware and Windows configuration.
3. Validates WSL and Ubuntu.
4. Installs or updates Microsoft Foundry Local.
5. Downloads the selected local language model.
6. Performs a repeatable local inference smoke test.
7. Runs a basic end-to-end benchmark.
8. Produces CSV, JSON, Markdown and telemetry output.

## Manual Run

If you have already cloned the repository:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Start-Lab.ps1 -BenchmarkRuns 3
```

When `-Model` is omitted, the toolkit lists the available CPU chat model
variants and asks the user to select a number, alias or model ID. Aliases are
resolved to the exact CPU variant ID so Foundry cannot switch back to a virtual
WebGPU adapter. For an unattended run, supply the model explicitly:

```powershell
.\Start-Lab.ps1 -Model phi-4-mini -BenchmarkRuns 3
```

Foundry Local installation may require a new PowerShell session so the `foundry` command is added to `PATH`. If the script returns exit code `3010`, close and reopen PowerShell 7, then run the lab again.

The toolkit detects both the earlier service-based Foundry Local CLI and the
replacement command surface introduced in Foundry Local CLI 0.10.

## Run Individual Stages

```powershell
.\scripts\Test-DeveloperImage.ps1
.\scripts\Install-AITooling.ps1
.\scripts\Test-LocalInference.ps1
.\scripts\Invoke-Benchmark.ps1 -Runs 3
```

The inference and benchmark scripts also prompt for a model when `-Model` is
not supplied.

## Repository Layout

```text
Windows365-AI-Developer-Kit
├── Install.ps1
├── Start-Lab.ps1
├── scripts
│   ├── Common.ps1
│   ├── Test-DeveloperImage.ps1
│   ├── Install-AITooling.ps1
│   ├── Test-LocalInference.ps1
│   └── Invoke-Benchmark.ps1
├── docs
├── results
├── ARCHITECTURE.md
└── CONTRIBUTING.md
```

Generated output is written beneath `results`:

```text
results
├── benchmarks
└── inventory
```

## Roadmap

### Version 0.1

- Bootstrap installer
- Prerequisite validation
- Foundry Local installation
- Interactive model selection and download
- Benchmark automation

### Version 0.2

- Azure AI Foundry comparison
- HTML reporting
- Sample AI app

### Version 0.3

- GPU benchmarking
- Multiple models
- Automated charts

### Version 1.0

- Production-ready toolkit
- PowerShell module
- GitHub Actions
- Automated testing

## Documentation

- [Architecture](ARCHITECTURE.md)
- [Contributing](CONTRIBUTING.md)
- [Lab notes](docs/Lab-Notes.md)

## Important

This is an early lab version built against preview tooling. Review generated
results and command output before relying on them. The benchmark intentionally
measures the practical end-to-end experience rather than claiming scientific
model performance.
