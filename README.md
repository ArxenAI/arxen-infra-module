# arxen-infra-module

Reusable infrastructure modules for Arxen "golden paths".

## What this repo provides
Versioned, reusable modules for:
- Kubernetes foundations (AKS/EKS/GKE building blocks)
- Networking and private connectivity
- Key management and secrets integrations
- Observability foundations (logging/metrics/tracing)
- AI/RAG primitives (storage, vector DB components, access boundaries)

## How it’s used
- Consumed by `arxen-infra-live` (environment stacks)
- Triggered by workflows in `arxen-workflows` or an IaC runner (e.g., Spacelift/TFC)

## Versioning
- Use semantic versioning via tags (vMAJOR.MINOR.PATCH)
- Changes must be reviewed and documented
