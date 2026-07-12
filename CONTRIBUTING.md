# Contributing

Thank you for helping improve the Windows 365 AI Developer Kit. This project is intended for Windows 365 admins, MVPs, Microsoft partners, enterprise customers and developers building local AI workflows on Cloud PCs.

## Development Environment

Use a Windows 365 Cloud PC where possible, ideally provisioned from the **Image with Developer Configuration (preview)** gallery image.

Expected tools:

- PowerShell 7
- Git
- VS Code
- WSL Ubuntu
- Python
- Node.js
- Azure CLI
- Microsoft Foundry Local

The toolkit should detect existing tools and avoid reinstalling components that are already present.

## Coding Style

- Use PowerShell 7.
- Use approved PowerShell verbs.
- Write advanced functions with `[CmdletBinding()]`.
- Include comment-based help for scripts and reusable functions.
- Prefer native Windows tooling.
- Keep scripts modular and focused on one stage.
- Use `Write-Verbose` for diagnostic detail.
- Fail gracefully with actionable error messages.
- Return meaningful exit codes.
- Avoid duplicated code by using shared helpers in `scripts\Common.ps1`.

## Testing

Before opening a pull request, run the checks that are practical for your environment:

```powershell
.\scripts\Test-DeveloperImage.ps1
.\scripts\Install-AITooling.ps1
.\scripts\Test-LocalInference.ps1 -Model phi-4-mini
.\scripts\Invoke-Benchmark.ps1 -Model phi-4-mini -Runs 1
```

For syntax-only validation:

```powershell
Get-ChildItem -Recurse -Filter *.ps1 | ForEach-Object {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors) { $errors | Format-List; throw "PowerShell parse failed: $($_.FullName)" }
}
```

## Pull Requests

Pull requests should include:

- A concise summary of the change.
- The Windows 365 / Windows version used for validation.
- Commands run during testing.
- Any known limitations, preview-tooling caveats or follow-up work.
- Screenshots when the change affects user-facing output.

Keep PRs focused. Large roadmap items are easier to review when they are split into installer, validation, benchmarking, reporting or sample-app changes.

## Documentation

Update documentation in the same PR as behaviour changes. At minimum, review:

- `README.md`
- `ARCHITECTURE.md`
- `docs\Lab-Notes.md`
- `docs\Screenshot-Guide.md`

## Security

Do not commit tenant names, usernames, access tokens, benchmark output containing sensitive prompts, screenshots with identifying data, or generated inventory from customer environments.
