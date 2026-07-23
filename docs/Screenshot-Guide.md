# Screenshot guide

Use **Win + Shift + S** and save the images in `results\screenshots`.

The scripts deliberately generate evidence and prepare the relevant windows, but they do not silently capture the whole desktop. This avoids accidentally including tenant names, usernames, notifications, tokens, or other sensitive information.

## Before running the lab

### 01 – Provisioning policy

Capture the Windows 365 provisioning policy with:

- Image type set to **Gallery image**
- **Image with Developer Configuration (preview)** selected
- Windows 365 Enterprise or Flex Dedicated provisioning context

Blur tenant names and user details before publishing.

### 02 – Cloud PC specification

Capture the Cloud PC overview showing:

- 16 vCPU
- 64 GB RAM
- Storage allocation
- Windows version

## Developer image validation

Run:

```powershell
.\scripts\Test-DeveloperImage.ps1
```

### 03 – First sign-in desktop

Show the clean developer-oriented desktop and taskbar.

### 04 – Preinstalled tools

Capture the validation table showing PowerShell, VS Code, Python, Node.js, Git, Azure CLI and .NET.

### 05 – Visual Studio Code extensions

Open VS Code and show the included Microsoft extensions.

### 06 – WSL Ubuntu

Run:

```powershell
wsl --list --verbose
wsl
```

Capture the working Ubuntu prompt.

## Foundry Local setup

### 07 – Foundry Local installation

Capture:

```powershell
winget install --id Microsoft.FoundryLocal --exact
foundry --version
```

### 08 – Local model catalogue

Capture:

```powershell
foundry model list --filter device=CPU
```

### 09 – Phi model details

Capture:

```powershell
foundry model show phi-4-mini
```

### 10 – Model download

Capture the model download progress:

```powershell
foundry model download phi-4-mini
```

### 11 – Service endpoint

Capture:

```powershell
foundry status
foundry cache list
```

## Local inference

### 12 – Interactive prompt

Run:

```powershell
foundry run phi-4-mini
```

Suggested prompt:

> In five concise points, explain the practical considerations for running a local language model on a Windows 365 Cloud PC.

Capture both the prompt and response.

### 13 – Task Manager during inference

Open Task Manager before submitting a longer prompt:

```powershell
taskmgr
```

Show CPU and memory utilisation. Avoid implying the chart is a controlled scientific benchmark.

## Benchmark results

Run:

```powershell
.\scripts\Invoke-Benchmark.ps1 -Model phi-4-mini -Runs 3
```

### 14 – Benchmark summary

Capture the PowerShell summary table.

### 15 – Generated evidence

Show:

- `results\benchmarks`
- CSV results
- Markdown summary
- Per-run output
- Telemetry CSV files

## Final article image

### 16 – Ready-to-code AI workstation

Arrange:

- VS Code on the left
- Foundry Local terminal on the right
- Task Manager visible behind or alongside
- No notifications or identifying tenant details

This should be the strongest hero image for the practical section of the blog.
