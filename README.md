# arxen-infra-module

Reusable OpenTofu modules — the **Golden Paths** of the Arxen platform. Each module is a secure, opinionated building block that enforces platform standards by default. Consumed by [`arxen-infra-live`](../arxen-infra-live) and surfaced to developers via `arxen-templates`.

> **Not a technical reader?** See [`docs/overview-for-everyone.md`](docs/overview-for-everyone.md) for a plain-language explanation of everything in this repository.
> **New to the team?** See [`docs/onboarding-for-engineers.md`](docs/onboarding-for-engineers.md) for a technical deep-dive covering architecture decisions, security patterns, and contribution guidelines.

---

## What This Repository Provides

A catalog of pre-approved, production-hardened modules for building Arxen tenant environments. Security controls are non-overridable by design — the platform team owns the baseline so product teams don't have to.

### Azure Modules (MVP)

| Module | Purpose |
|---|---|
| [`azure/vnet`](modules/azure/vnet/) | Virtual Network with four purpose-built subnets and NSGs — the network foundation everything else builds on |
| [`azure/aks`](modules/azure/aks/) | Private AKS cluster with Workload Identity, Calico network policy, Azure Policy, and AAD-only RBAC |
| [`azure/keyvault`](modules/azure/keyvault/) | Key Vault with private endpoint, purge protection, soft-delete, and RBAC authorization model |
| [`azure/acr`](modules/azure/acr/) | Premium Container Registry with private endpoint — public access permanently disabled |
| [`azure/storage`](modules/azure/storage/) | Blob Storage Account with private endpoint and encryption at rest |
| [`azure/postgresql`](modules/azure/postgresql/) | PostgreSQL Flexible Server in a delegated subnet with SSL enforcement and geo-redundant backups |
| [`azure/ai-workspace`](modules/azure/ai-workspace/) | Azure ML Workspace wired to Key Vault, Storage, and ACR — private-only by default |
| [`azure/observability`](modules/azure/observability/) | Log Analytics Workspace + Application Insights as the central telemetry sink for all other modules |

### Common Modules (Cloud-Agnostic)

| Module | Purpose |
|---|---|
| [`common/k8s-namespace`](modules/common/k8s-namespace/) | Kubernetes Namespace with default-deny NetworkPolicy and viewer/editor RoleBindings |
| [`common/k8s-labels`](modules/common/k8s-labels/) | Utility module that produces a standardized Kubernetes label map — no cloud resources created |

---

## Module Assembly Order

Modules depend on each other's outputs. A typical full-stack deployment follows this sequence:

```
vnet ──────────────────────────────────────────┐
observability ──────────────────────────────── ├──► aks ──► k8s-namespace
keyvault ──────────────────────────────────┐   │
storage  ──────────────────────────────────┼──►├──► ai-workspace
acr      ──────────────────────────────────┘   │
postgresql ─────────────────────────────────── ┘
```

All wiring is explicit — modules never reach out to each other directly. Outputs from one module are passed as inputs to the next in the calling stack.

---

## Security Posture

Every module enforces the following without exception:

- **Encryption at rest:** All storage, databases, and OS disks use managed keys (CMK required in `prod`).
- **No public access:** Databases, vaults, registries, and storage accounts are private-only. Public access is opt-in via variable and only permitted in `dev`.
- **No static credentials:** Services authenticate with Azure Managed Identities. No passwords, no API keys stored in config.
- **Least-privilege IAM:** No `*` wildcards in any role assignment or network rule.
- **Private networking:** All PaaS services use Private Endpoints linked to `snet-private-endpoints` from `azure/vnet`.
- **Sensitive outputs marked:** Any output that contains a secret, connection string, or kubeconfig has `sensitive = true` — it will not be printed in plan output.

---

## Module Interface Contract

Every module — regardless of cloud provider — must implement the following standard interface to be usable by `arxen-infra-live` and `arxen-templates`.

### Required variables (all modules)

```hcl
variable "tenant_id" {
  type        = string
  description = "Arxen tenant identifier (internal UUID). Used for tagging and naming."
}

variable "environment" {
  type        = string
  description = "Deployment environment: 'dev', 'stage', or 'prod'."
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be 'dev', 'stage', or 'prod'."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to merge with default module tags."
  default     = {}
}
```

### Required outputs (all modules)

```hcl
output "resource_id" {
  description = "The primary resource identifier (ARM ID, ARN, or self-link)."
  value       = <resource>.id
}

output "resource_name" {
  description = "The resource name as provisioned in the cloud."
  value       = <resource>.name
}
```

### File structure (all modules)

```
modules/<cloud>/<module-name>/
  main.tf       # Resource definitions
  variables.tf  # All inputs with type + description + default
  outputs.tf    # All outputs with description and sensitive flag
  versions.tf   # required_providers version constraints only
  README.md     # Generated by terraform-docs
```

---

## How to Consume a Module

Pin to a Git tag in your live stack (`arxen-infra-live`):

```hcl
module "vnet" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/vnet?ref=v1.0.0"

  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

module "aks" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/aks?ref=v1.0.0"

  tenant_id                  = var.tenant_id
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  subscription_id            = var.subscription_id
  azure_ad_tenant_id         = var.azure_ad_tenant_id
  kubernetes_version         = "1.30"
  node_count                 = 3
  vnet_subnet_id             = module.vnet.aks_nodes_subnet_id        # output from vnet
  log_analytics_workspace_id = module.observability.resource_id       # output from observability
  admin_group_object_ids     = [var.platform_admins_group_id]
}
```

---

## Versioning Policy

Modules are versioned via Git tags. Callers pin to a tag and upgrade explicitly.

| Change | Version bump | Impact |
|---|---|---|
| Breaking change to variables or outputs | `MAJOR` (v1 → v2) | Callers must update |
| New optional variable or output | `MINOR` (v1.0 → v1.1) | Backwards-compatible |
| Bug fix, security patch, docs update | `PATCH` (v1.0.0 → v1.0.1) | Safe to apply immediately |

---

## Constraints

- **No `backend {}` blocks** — state is managed by the caller (`arxen-infra-live`).
- **No `provider {}` blocks** — only `required_providers` version constraints are defined here.
- **No hardcoded values** — no IP addresses, CIDR blocks, regions, subscription IDs, or account IDs.
- **No environment-specific defaults** — modules are generic; the caller supplies environment context.

---

## Roadmap

The same module catalog will be mirrored for AWS and GCP:

| Azure | AWS | GCP |
|---|---|---|
| `azure/aks` | `aws/eks` | `gcp/gke` |
| `azure/vnet` | `aws/vpc` | `gcp/vpc` |
| `azure/keyvault` | `aws/secrets-manager` | `gcp/secret-manager` |
| `azure/acr` | `aws/ecr` | `gcp/artifact-registry` |
| `azure/storage` | `aws/s3` | `gcp/gcs` |
| `azure/postgresql` | `aws/rds` | `gcp/cloudsql` |
| `azure/ai-workspace` | `aws/bedrock-workspace` | `gcp/vertex-workspace` |
| `azure/observability` | `aws/observability` | `gcp/observability` |

Each new cloud module must implement the same `tenant_id`, `environment`, `tags` variable contract and the `resource_id`, `resource_name` output contract.

---

## Related Repositories

| Repo | Role |
|---|---|
| `arxen-infra-live` | Calls these modules to build real environments (dev, stage, prod) |
| `arxen-templates` | Backstage templates that scaffold new tenant stacks using these modules |
| `arxen-workflows` | CI/CD pipelines (OpenTofu plan/apply) triggered by changes to `arxen-infra-live` |
