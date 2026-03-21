# arxen-infra-module — Claude Code Guide

## Purpose

Reusable OpenTofu modules — the "Golden Paths" of the platform. Consumed by `arxen-infra-live` and surfaced to developers via `arxen-templates`. Contains no live environments and no backend state configuration.

## Architecture

```
modules/
  <module-name>/
    main.tf         # Resource definitions
    variables.tf    # All input variables (with type + description)
    outputs.tf      # All outputs (ARNs, IDs, endpoints)
    README.md       # Auto-generated via terraform-docs
```

## Module Standards

**File structure is mandatory** — never put everything in a single file.

**Every variable must have:**
```hcl
variable "example" {
  type        = string
  description = "Brief description of what this controls."
  default     = null  # Omit if required
}
```

**Every output must have:**
```hcl
output "cluster_endpoint" {
  description = "The Kubernetes API server endpoint."
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = false  # Set true for kubeconfig, tokens, etc.
}
```

**Tagging:** Every module must accept a `tags` variable and merge it:
```hcl
variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}
# Usage: tags = merge(local.default_tags, var.tags)
```

**Iteration:** Use `for_each` over `count` for all collections.

**Resource naming:** `snake_case`, no resource type in name.

## Security Defaults (Non-Negotiable)

- Storage: encryption at rest with KMS/CMK always enabled
- Databases: `publicly_accessible = false` always
- IAM/RBAC: no `*` wildcards in actions or resources
- Network: private endpoints by default, public access opt-in via variable

## Constraints

- Never define a `terraform { backend {} }` block — state is the caller's responsibility
- Never configure a `provider {}` block — only `required_providers` version constraints
- Never hardcode IP addresses, CIDR blocks, regions, or account IDs
- Mark sensitive outputs (`sensitive = true`) for kubeconfigs, connection strings, tokens
