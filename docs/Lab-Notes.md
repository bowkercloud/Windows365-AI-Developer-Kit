# Lab notes

## Baseline

This project assumes:

- Windows 365 Enterprise or Windows 365 Flex Dedicated
- 16 vCPU Cloud PC
- Image with Developer Configuration (preview)
- Windows 11
- Internet access for first-time Foundry Local execution-provider and model downloads
- Local administrator rights for the Foundry Local installation

## Why 16 vCPU?

Microsoft describes the 16 vCPU tier as extending CPU-only local AI to larger reasoning and coding models. It remains primarily text-focused and does not provide the image-generation capabilities of GPU Cloud PCs.

## Default model

The scripts use the `phi-4-mini` alias. Foundry Local resolves an alias to the most appropriate available model variant for the detected hardware.

To see the exact resolved model with Foundry Local CLI 0.10 or later:

```powershell
foundry model show phi-4-mini
```

The toolkit automatically maps this and other commands when an earlier
service-based Foundry Local CLI is installed.

## Benchmark interpretation

The included benchmark is an end-to-end developer-experience test. It measures complete CLI prompt/response time while sampling CPU and available memory.

It is not intended to provide:

- Formal tokens-per-second figures
- A comparison with Azure-hosted model latency
- A controlled model-quality evaluation
- A production capacity estimate

Use the output to document the practical experience on this specific Cloud PC configuration.

## Preview warning

Both the Developer Configuration gallery image and Foundry Local capabilities discussed in this lab may be in preview. Validate current Microsoft documentation before publishing screenshots or command examples.
