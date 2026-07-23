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

## Model selection

When no model is supplied, the toolkit lists CPU chat model variants and
prompts for an alias or model ID. The explicit CPU variant view is important
on Cloud PCs where virtual display adapters can cause Foundry Local to prefer
a WebGPU variant in its default catalogue view. The selected alias is resolved
to its exact CPU variant ID before the model is downloaded or loaded.

For example:

```powershell
foundry model info phi-4-mini
```

The toolkit automatically maps commands that differ between the earlier
service-based CLI and Foundry Local CLI 0.10.

## Benchmark interpretation

The included benchmark is an end-to-end developer-experience test. It measures complete CLI prompt/response time while sampling CPU and available memory.

It is not intended to provide:

- Formal tokens-per-second figures
- A comparison with Azure-hosted model latency
- A controlled model-quality evaluation
- A production capacity estimate

Use the output to document the practical experience on this specific Cloud PC configuration.

## Preview warning

Both the Developer Configuration gallery image and Foundry Local capabilities
discussed in this lab may be in preview. Validate current Microsoft
documentation before relying on command examples.
