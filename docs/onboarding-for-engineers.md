# Engineering Onboarding — arxen-infra-module

> Welcome to the team. This document explains what this repository is, why it is built the way it is, and what you need to know to contribute or consume from it confidently — regardless of your prior experience with infrastructure-as-code.

---

## Table of Contents

1. [Repository Role in the Arxen Ecosystem](#1-repository-role-in-the-arxen-ecosystem)
2. [Technology Choices and Why](#2-technology-choices-and-why)
3. [The Golden Path Pattern](#3-the-golden-path-pattern)
4. [Repository Structure](#4-repository-structure)
5. [Module Anatomy](#5-module-anatomy)
6. [Module Interface Contract](#6-module-interface-contract)
7. [Security Architecture](#7-security-architecture)
8. [Module Catalog Deep Dive](#8-module-catalog-deep-dive)
9. [How Modules Wire Together](#9-how-modules-wire-together)
10. [Versioning Strategy](#10-versioning-strategy)
11. [Contributing a New Module](#11-contributing-a-new-module)
12. [Consuming a Module](#12-consuming-a-module)
13. [Common Pitfalls](#13-common-pitfalls)
14. [Roadmap](#14-roadmap)

---

## 1. Repository Role in the Arxen Ecosystem

Arxen is an **Internal Developer Platform (IDP)**. The platform is split across several repositories, each with a clearly bounded responsibility:

| Repository | Responsibility |
|---|---|
| **`arxen-infra-module`** (this repo) | Reusable, versioned OpenTofu module library — the blueprints |
| `arxen-infra-live` | Calls these modules to instantiate real environments (dev/stage/prod) per tenant |
| `arxen-templates` | Backstage scaffolding templates that generate live stacks for new tenants |
| `arxen-workflows` | CI/CD pipelines (plan/apply) triggered by changes in `arxen-infra-live` |

**This repo contains no live state, no backend configuration, and no provider configuration.** It is a pure module library. Think of it as an npm package registry for infrastructure — you publish versioned modules here, and callers `source` them by tag.

The separation is intentional: modules evolve independently of the environments that consume them. A breaking change in a module does not automatically affect any live environment — callers choose when to upgrade.

---

## 2. Technology Choices and Why

### OpenTofu (not Terraform)

We use [OpenTofu](https://opentofu.org/), the open-source fork of Terraform maintained by the Linux Foundation. The module syntax is identical to Terraform HCL — if you know Terraform, you already know OpenTofu. The choice is purely strategic: OpenTofu has a stable open governance model with no risk of license changes affecting our workflows.

If you are new to HCL, the key concepts to learn first are:
- `resource` blocks — declare cloud resources
- `variable` blocks — declare inputs
- `output` blocks — declare values the module exposes to callers
- `locals` — intermediate computed values within a module
- `for_each` — iterate over a map or set to create multiple resources

### Microsoft Azure (MVP Cloud)

Azure is the initial target because it is the primary cloud contract for Arxen's first enterprise customers. The module catalog is designed to be cloud-symmetric: AWS and GCP modules will mirror the same interface once Azure reaches stability. See [Section 14](#14-roadmap).

### No Terragrunt, No Wrapper Tooling

The modules are plain OpenTofu. No Terragrunt, no CDK, no wrapper. This keeps the consumption pattern simple and auditable — a caller is just a `.tf` file with `module {}` blocks. Orchestration complexity lives in `arxen-infra-live` and `arxen-workflows`, not here.

---

## 3. The Golden Path Pattern

A **Golden Path** is a pre-built, pre-approved route through a decision space. The concept originated at Netflix and Spotify to describe how platform teams reduce cognitive load for application teams.

In practice:

- **Without Golden Paths:** Every team makes independent decisions about networking, encryption, IAM, naming, tagging. Security reviews find inconsistencies. Audits are expensive. Incidents happen because someone forgot to enable a setting.
- **With Golden Paths:** Secure, correct infrastructure is the default. Teams assemble proven building blocks. The platform team owns the security baseline; product teams own their workloads.

In this repo, Golden Path means:

1. **Security controls are non-overridable.** Private cluster, encryption, no public DB access — these are hardcoded in `main.tf`. They are not variables. A caller cannot disable them by accident or convenience.
2. **The interface is opinionated but narrow.** Modules expose only the configuration knobs that are safe to vary (VM size, node count, retention days). Everything else is decided by the platform.
3. **Outputs are always available.** Every module exposes `resource_id` and `resource_name` so callers can wire modules together without hard-coding resource identifiers.

---

## 4. Repository Structure

```
arxen-infra-module/
├── modules/
│   ├── azure/                  # Azure-specific modules (MVP)
│   │   ├── aks/                # Azure Kubernetes Service
│   │   ├── vnet/               # Virtual Network + subnets
│   │   ├── keyvault/           # Key Vault
│   │   ├── acr/                # Container Registry
│   │   ├── storage/            # Blob Storage
│   │   ├── postgresql/         # PostgreSQL Flexible Server
│   │   ├── ai-workspace/       # Azure ML / AI Foundry workspace
│   │   └── observability/      # Log Analytics + App Insights
│   ├── aws/                    # Planned — mirrors azure/ structure
│   ├── gcp/                    # Planned — mirrors azure/ structure
│   └── common/                 # Cloud-agnostic modules
│       ├── k8s-namespace/      # Kubernetes Namespace + RBAC + NetworkPolicy
│       └── k8s-labels/         # Standard label map utility
├── docs/                       # Documentation
│   ├── overview-for-everyone.md
│   └── onboarding-for-engineers.md (this file)
├── SPEC.md                     # Formal module specification
├── CLAUDE.md                   # AI assistant guidelines for this repo
└── README.md                   # Repository overview
```

---

## 5. Module Anatomy

Every module has exactly five files. No exceptions.

```
modules/<cloud>/<module-name>/
├── main.tf         # Resource declarations
├── variables.tf    # Input variable declarations
├── outputs.tf      # Output value declarations
├── versions.tf     # required_providers block only
└── README.md       # Auto-generated by terraform-docs
```

### `main.tf`

Contains all `resource` blocks and `locals`. Security defaults that must not be overridable are hardcoded here — not in `variables.tf`. If you see a setting in `main.tf` that looks like it "should be a variable," that is usually deliberate.

```hcl
resource "azurerm_kubernetes_cluster" "main" {
  name                = local.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Security defaults — these are intentionally NOT variables
  private_cluster_enabled       = true
  azure_policy_enabled          = true
  local_account_disabled        = true
  role_based_access_control_enabled = true

  # Caller-controlled settings
  kubernetes_version = var.kubernetes_version
  node_resource_group = ...
}
```

### `variables.tf`

Every variable must have `type`, `description`, and either a `default` or be clearly required (no default). Validation blocks are encouraged for variables with a constrained domain.

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment: 'dev', 'stage', or 'prod'."
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod."
  }
}
```

### `outputs.tf`

Every output needs `description` and a `sensitive` flag. Never omit `sensitive = true` for connection strings, kubeconfigs, tokens, or instrumentation keys.

```hcl
output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster. Do not store in plaintext."
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}
```

### `versions.tf`

Only a `terraform {}` block with `required_providers`. No `backend {}`, no `provider {}` configuration. Provider configuration is the caller's responsibility.

```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.90, < 5.0"
    }
  }
}
```

---

## 6. Module Interface Contract

All modules — across all clouds — implement a standard contract. This allows `arxen-infra-live` and `arxen-templates` to consume any module with the same calling pattern.

### Standard inputs (every module)

| Variable | Type | Required | Purpose |
|---|---|---|---|
| `tenant_id` | `string` | yes | Arxen tenant UUID — used in resource naming and tagging |
| `environment` | `string` | yes | `dev`, `stage`, or `prod` — validated via constraint |
| `tags` | `map(string)` | no (default `{}`) | Caller-supplied tags merged on top of module defaults |

### Standard outputs (every module)

| Output | Sensitive | Purpose |
|---|---|---|
| `resource_id` | no | Primary resource identifier (ARM ID, ARN, or self-link) |
| `resource_name` | no | Resource name as provisioned in the cloud |

Modules with sensitive outputs add them on top of this base. The two standard outputs are always present so callers can reference any module uniformly.

### Tagging convention

Every module defines a `local.default_tags` map and merges it with `var.tags`:

```hcl
locals {
  default_tags = {
    tenant_id  = var.tenant_id
    environment = var.environment
    managed_by = "opentofu"
    module     = "arxen-infra-module/azure/<module-name>"
  }
  tags = merge(local.default_tags, var.tags)
}
```

Caller tags win on conflict (merge order). This means a caller can override `environment` in the tag if they need to, but `managed_by` and `module` are always present unless explicitly overridden.

---

## 7. Security Architecture

### Private Networking by Default

Every PaaS service (Key Vault, Storage, ACR, PostgreSQL, ML Workspace) deploys a **Private Endpoint** into `snet-private-endpoints` from the `azure/vnet` module. The public network access flag is `false` by default and cannot be set to `true` in `stage` or `prod`.

Private Endpoints use the Azure Private Link service. The endpoint gets a private IP in your VNet. A Private DNS Zone (`privatelink.<service>.azure.com`) resolves the service's public FQDN to that private IP inside the VNet. External DNS (from the public internet) still resolves to the public IP, but the network-level firewall on the service rejects that traffic.

```
App in AKS pod
  → resolves "mykeyvault.vault.azure.net"
  → Private DNS Zone returns 10.0.3.5 (private endpoint IP)
  → traffic stays inside VNet
  → Key Vault accepts (source is in approved subnet)
```

### Managed Identity (No Static Credentials)

All service-to-service authentication uses **Azure Managed Identities**. The AKS cluster uses a `SystemAssigned` identity for control-plane operations. Pods authenticate to Azure services using **Workload Identity** — a federation between Kubernetes service accounts and Azure AD using OIDC.

The flow:
1. AKS exposes an OIDC issuer URL (`module.aks.oidc_issuer_url`).
2. A Federated Identity Credential on a User-Assigned Managed Identity trusts tokens issued by that OIDC issuer for a specific Kubernetes `ServiceAccount` (identified by namespace + name).
3. The pod's service account token is exchanged for an Azure AD token with no static credentials stored anywhere.

No secrets are written to Kubernetes Secrets for Azure service authentication. The only Kubernetes Secrets that should exist are application-level secrets fetched from Key Vault via the Secrets Store CSI Driver.

### Encryption

| Layer | Default |
|---|---|
| Storage blobs | Microsoft-managed keys (MMK) in dev/stage, CMK via Key Vault in prod |
| PostgreSQL data | Storage-level encryption always enabled |
| AKS OS disks | Managed disk encryption; CMK via `disk_encryption_set_id` (required in prod) |
| Key Vault HSM | Platform-managed in Standard tier; HSM-backed in Premium (prod) |
| Data in transit | TLS enforced on all services; `ssl_enforcement_enabled = true` on PostgreSQL |

### IAM / RBAC

- No `*` wildcards in any role assignment or action list anywhere in this repository.
- AKS uses `local_account_disabled = true` — there is no `cluster-admin` kubeconfig that bypasses AAD. All access goes through Azure AD group membership.
- Key Vault uses the RBAC authorization model (not legacy access policies) — access is granted via role assignments on the vault or individual secrets/keys/certificates.

---

## 8. Module Catalog Deep Dive

### `azure/vnet` — Network Foundation

Creates the VNet and four subnets. Everything else in the Azure stack depends on this module's outputs.

**Subnets:**
| Subnet | CIDR source | Purpose |
|---|---|---|
| `snet-aks-nodes` | `var.aks_nodes_subnet_cidr` | AKS default node pool NICs |
| `snet-aks-pods` | `var.aks_pods_subnet_cidr` | Pod IPs (Azure CNI overlay) |
| `snet-private-endpoints` | `var.private_endpoints_subnet_cidr` | Private Endpoints for all PaaS services |
| `snet-appgw` | `var.appgw_subnet_cidr` | Application Gateway (optional, for ingress) |

Each subnet gets its own NSG. The default NSG rules allow VNet-internal traffic and block everything inbound from the internet.

**Key outputs used by other modules:**
- `aks_nodes_subnet_id` → consumed by `azure/aks`
- `private_endpoints_subnet_id` → consumed by `azure/keyvault`, `azure/acr`, `azure/storage`, `azure/ai-workspace`
- `vnet_id` → consumed by modules that create Private DNS Zone VNet links

---

### `azure/observability` — Telemetry Foundation

Creates a Log Analytics Workspace and optionally an Application Insights instance backed by that workspace (workspace-based App Insights, not the legacy classic mode).

Must be deployed before `azure/aks` because the AKS OMS agent requires a workspace ID at cluster creation time.

**Key outputs:**
- `resource_id` → consumed by `azure/aks` as `log_analytics_workspace_id`
- `workspace_id` (the GUID, not the ARM ID) → used in `azurerm_monitor_diagnostic_setting` resources
- `application_insights_connection_string` (sensitive) → should be written to Key Vault, never passed directly to application config

---

### `azure/keyvault` — Secrets and Key Management

All security defaults are hardcoded:
- `public_network_access_enabled = false`
- `purge_protection_enabled = true`
- `soft_delete_retention_days = 90`
- RBAC authorization model (not vault access policies)

The private endpoint and private DNS zone for `privatelink.vaultcore.azure.net` are created by the module. You must pass `private_endpoint_subnet_id` and `vnet_id` from `azure/vnet`.

**Important:** After provisioning, the caller must grant role assignments on the vault. The module does not create any role assignments — that is the live stack's responsibility to avoid implicit privilege escalation.

---

### `azure/aks` — Compute Backbone

The most complex module. Depends on both `azure/vnet` and `azure/observability` outputs.

Security defaults hardcoded in `main.tf` (not overridable via variables):

| Setting | Value | Rationale |
|---|---|---|
| `private_cluster_enabled` | `true` | API server has no public endpoint |
| `azure_policy_enabled` | `true` | Admission controller policy enforcement |
| `oidc_issuer_enabled` | `true` | Required for Workload Identity |
| `workload_identity_enabled` | `true` | Pod-level Azure AD federation |
| `network_plugin` | `"azure"` | Azure CNI — pods get VNet IPs, enabling pod-level NSG enforcement |
| `network_policy` | `"calico"` | Pod-to-pod NetworkPolicy enforcement |
| `local_account_disabled` | `true` | No static kubeconfig bypass |
| `role_based_access_control_enabled` | `true` | Kubernetes RBAC always on |
| `msi_auth_for_monitoring_enabled` | `true` | OMS agent uses managed identity, no workspace key stored |

**Workload Identity wiring** (post-provisioning, in live stack):
```hcl
resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.environment}-app-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
}

resource "azurerm_federated_identity_credential" "app" {
  name                = "app-federated-credential"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.app.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url          # from aks module output
  subject             = "system:serviceaccount:my-ns:my-sa" # namespace:serviceaccount
}
```

**ACR pull access** must be granted explicitly after both `aks` and `acr` are provisioned:
```hcl
resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.acr.resource_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}
```

---

### `azure/acr` — Container Registry

Premium SKU is the only option — it is required for Private Endpoints. Public access is unconditionally disabled in `main.tf`. The module creates the private endpoint and private DNS zone (`privatelink.azurecr.io`).

Output `registry_id` is consumed by `azure/ai-workspace`.

---

### `azure/storage` — Blob Storage

Standard LRS in dev, GRS in stage/prod (controlled by the `redundancy` variable). Private endpoint for `privatelink.blob.core.windows.net`. All public access disabled. Hierarchical Namespace (ADLS Gen2) is opt-in via `is_hns_enabled` for teams that need Azure Data Lake semantics.

Output `account_id` is consumed by `azure/ai-workspace`.

---

### `azure/postgresql` — Managed Database

Flexible Server architecture (not Single Server — that is deprecated). The server is deployed into a delegated subnet (`Microsoft.DBforPostgreSQL/flexibleServers` delegation) — it does not use a Private Endpoint. Private DNS zone (`privatelink.postgres.database.azure.com`) resolves the FQDN to the delegated subnet IP.

The caller must pass a subnet with the correct delegation already configured. If using `azure/vnet`, add a delegated subnet variable — the base `vnet` module does not currently create one by default (this is a known gap).

---

### `azure/ai-workspace` — Machine Learning Workspace

Last in the dependency chain. Requires `azure/keyvault`, `azure/storage`, and `azure/acr` outputs before it can be applied. Application Insights integration is optional (pass `null` to skip).

Private endpoint covers the ML Workspace API (`privatelink.api.azureml.ms`). After provisioning, the workspace's `SystemAssigned` identity needs role assignments on Key Vault, Storage, and ACR for the workspace to function — the module does not create these to avoid implicit privilege escalation.

---

### `common/k8s-namespace` — Kubernetes Namespace

Cloud-agnostic. Uses the Kubernetes provider, not any cloud provider. Creates:
- A `Namespace`
- A `default-deny-ingress` `NetworkPolicy` (always)
- An optional `default-deny-egress` `NetworkPolicy` with a DNS egress exemption (port 53 UDP/TCP to `kube-dns`)
- `viewer` `RoleBinding` → `view` ClusterRole
- `editor` `RoleBinding` → `edit` ClusterRole

Teams are added to these bindings by passing their Azure AD group object IDs.

---

### `common/k8s-labels` — Label Utility

No resources created. Pure `locals` computation. Produces a map conforming to [Kubernetes recommended labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/) plus Arxen-specific labels (`tenant_id`, `environment`, `managed_by`). Use this to stamp labels on every Kubernetes resource in live stacks.

```hcl
module "labels" {
  source      = "git::...//modules/common/k8s-labels?ref=v1.0.0"
  app         = "arxen-api"
  component   = "backend"
  tenant_id   = var.tenant_id
  environment = var.environment
}

resource "kubernetes_deployment" "app" {
  metadata {
    labels = module.labels.labels
  }
}
```

---

## 9. How Modules Wire Together

Modules never reference each other directly. Outputs are passed explicitly by the calling stack in `arxen-infra-live`. This keeps modules independently testable and prevents hidden coupling.

Typical dependency graph for a full tenant stack:

```
vnet
 ├── aks_nodes_subnet_id         ──────────────────────────────► aks.vnet_subnet_id
 ├── private_endpoints_subnet_id ──► keyvault.private_endpoint_subnet_id
 │                                ──► acr.private_endpoint_subnet_id
 │                                ──► storage (via caller)
 │                                ──► ai-workspace.private_endpoint_subnet_id
 └── vnet_id                     ──► keyvault.vnet_id
                                  ──► acr.vnet_id
                                  ──► ai-workspace.vnet_id

observability
 └── resource_id                 ──────────────────────────────► aks.log_analytics_workspace_id
     workspace_id                                                 (also used in diagnostic_settings)

keyvault
 └── vault_id                    ──────────────────────────────► ai-workspace.key_vault_id

storage
 └── account_id                  ──────────────────────────────► ai-workspace.storage_account_id

acr
 └── registry_id                 ──────────────────────────────► ai-workspace.container_registry_id

aks
 └── oidc_issuer_url             ─── (used in live stack for federated identity credentials)
     kubelet_identity_object_id  ─── (used in live stack for ACR pull role assignment)
```

---

## 10. Versioning Strategy

Modules are versioned via Git tags on the repository root. A single tag covers the entire module library — there is no per-module versioning. This means a version bump in one module bumps the tag for all modules. This is a deliberate simplicity trade-off: a single tag is easier to reason about for the MVP; per-module versioning can be introduced when the module count grows.

Callers pin to a specific tag:

```hcl
source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/aks?ref=v1.2.0"
```

The `//` in the source path is OpenTofu syntax for specifying a subdirectory within a Git repository. It is not a typo.

**Semver policy:**

| Change type | Bump | Examples |
|---|---|---|
| Removing or renaming a required variable | MAJOR | `resource_group_name` → `rg_name` |
| Removing or renaming an output | MAJOR | `cluster_id` removed |
| Adding a required variable | MAJOR | New required input without a default |
| Adding an optional variable or output | MINOR | New optional feature flag |
| Bug fix, security patch, refactor | PATCH | Fix incorrect CIDR default |
| Documentation only | PATCH | README update |

Before releasing a MAJOR version, post a migration guide in the PR description and notify all live stack owners.

---

## 11. Contributing a New Module

### Checklist before opening a PR

- [ ] Module has all five required files: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`
- [ ] All variables have `type` and `description`
- [ ] All outputs have `description` and `sensitive` flag
- [ ] `tenant_id`, `environment`, and `tags` variables are present
- [ ] `resource_id` and `resource_name` outputs are present
- [ ] Security defaults are hardcoded in `main.tf`, not exposed as variables
- [ ] No `backend {}` block in `versions.tf`
- [ ] No `provider {}` configuration block anywhere
- [ ] No hardcoded IP addresses, CIDR blocks, regions, or account IDs
- [ ] All sensitive outputs marked `sensitive = true`
- [ ] `for_each` used instead of `count` for all collections
- [ ] Resource names use `snake_case` with no resource type in the name
- [ ] Tags use `merge(local.default_tags, var.tags)` pattern
- [ ] `README.md` generated or updated with `terraform-docs`

### Naming conventions

- Module directory: `kebab-case` (e.g., `ai-workspace`, `k8s-namespace`)
- Resource blocks: `snake_case`, resource name does not repeat the resource type
  - Good: `resource "azurerm_key_vault" "main"`
  - Bad: `resource "azurerm_key_vault" "key_vault_main"`
- Local variables: `snake_case`
- Output names: `snake_case`, descriptive (prefer `vault_id` over just `id`)

### Generating README.md

Use [terraform-docs](https://terraform-docs.io/) from the module directory:

```bash
cd modules/azure/<your-module>
terraform-docs markdown table --output-file README.md .
```

The generated output covers inputs and outputs tables. Add a usage example and a security defaults section manually — `terraform-docs` does not generate those.

---

## 12. Consuming a Module

In your live stack (`arxen-infra-live`), reference the module by Git tag:

```hcl
# Step 1: Deploy the network foundation
module "vnet" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/vnet?ref=v1.0.0"

  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  address_space                  = ["10.0.0.0/16"]
  aks_nodes_subnet_cidr          = "10.0.0.0/22"
  aks_pods_subnet_cidr           = "10.0.4.0/22"
  private_endpoints_subnet_cidr  = "10.0.8.0/24"
}

# Step 2: Deploy the telemetry sink
module "observability" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/observability?ref=v1.0.0"

  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  retention_in_days   = var.environment == "prod" ? 90 : 30
}

# Step 3: Deploy the cluster — wire in vnet and observability outputs
module "aks" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/aks?ref=v1.0.0"

  tenant_id                  = var.tenant_id
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  subscription_id            = var.subscription_id
  azure_ad_tenant_id         = var.azure_ad_tenant_id
  kubernetes_version         = "1.30"
  node_count                 = var.environment == "prod" ? 5 : 2
  vnet_subnet_id             = module.vnet.aks_nodes_subnet_id        # explicit wiring
  log_analytics_workspace_id = module.observability.resource_id       # explicit wiring
  admin_group_object_ids     = [var.platform_admins_aad_group_id]
}
```

After `tofu init` and `tofu plan`, review the plan carefully before applying. Pay attention to `known after apply` values — some outputs (like `oidc_issuer_url`) are only available after the first apply, which means dependent resources (federated credentials) may require a second apply pass.

---

## 13. Common Pitfalls

### Two-pass applies

Some resources depend on values that are only known after another resource is created. The most common case: Federated Identity Credentials need `module.aks.oidc_issuer_url`, which is not known until the AKS cluster exists. Structure your live stack to apply in two passes if needed, or use `depends_on` to enforce ordering.

### `for_each` vs `count`

Never use `count` for resources that might change membership. If you use `count = length(var.subnets)` and later reorder the `subnets` list, Terraform will destroy and recreate resources. `for_each` uses stable keys, so reordering has no effect.

```hcl
# Bad
resource "azurerm_subnet" "main" {
  count = length(var.subnets)
  name  = var.subnets[count.index].name
}

# Good
resource "azurerm_subnet" "main" {
  for_each = { for s in var.subnets : s.name => s }
  name     = each.value.name
}
```

### `sensitive = true` propagation

In OpenTofu, if any input to an expression is `sensitive`, the output is also `sensitive`. This can cause plan output to show `(sensitive value)` in unexpected places. Do not work around this by wrapping values in `nonsensitive()` unless you have explicitly verified the value contains no secret material.

### Provider version ranges

Keep provider version constraints in `versions.tf` as open ranges (`>= 3.90, < 5.0`) rather than pinned exact versions. The caller's lock file (`.terraform.lock.hcl`) pins the exact version for reproducibility. Pinning in the module prevents callers from upgrading.

### No backend block in modules

If you accidentally add a `backend {}` block to a module's `versions.tf`, OpenTofu will error when the module is called from a root that already has a backend configured. This is one of the hardest constraints to remember — it has no syntax warning.

---

## 14. Roadmap

The Azure module catalog is MVP. The long-term goal is cloud-symmetric coverage:

| Azure | AWS | GCP | Status |
|---|---|---|---|
| `azure/vnet` | `aws/vpc` | `gcp/vpc` | AWS and GCP: planned |
| `azure/aks` | `aws/eks` | `gcp/gke` | AWS and GCP: planned |
| `azure/keyvault` | `aws/secrets-manager` | `gcp/secret-manager` | AWS and GCP: planned |
| `azure/acr` | `aws/ecr` | `gcp/artifact-registry` | AWS and GCP: planned |
| `azure/storage` | `aws/s3` | `gcp/gcs` | AWS and GCP: planned |
| `azure/postgresql` | `aws/rds` | `gcp/cloudsql` | AWS and GCP: planned |
| `azure/ai-workspace` | `aws/bedrock-workspace` | `gcp/vertex-workspace` | AWS and GCP: planned |
| `azure/observability` | `aws/observability` | `gcp/observability` | AWS and GCP: planned |

When adding a new cloud:
1. Create `modules/<cloud>/` directory mirroring the Azure structure.
2. Each module must implement the same `tenant_id`, `environment`, `tags` variable contract and `resource_id`, `resource_name` output contract.
3. Security defaults must be equivalent to their Azure counterparts — private networking, encryption, no static credentials.
4. Add the new modules to the roadmap table above and update `SPEC.md`.

Per-module versioning (rather than the current repo-level tag) is also being evaluated as the catalog grows — the trade-off is tooling complexity vs. independent release cadences.

---

## Further Reading

- [`SPEC.md`](../SPEC.md) — formal module specification (the authoritative source for interface rules)
- [`docs/overview-for-everyone.md`](overview-for-everyone.md) — non-technical overview for stakeholders
- [OpenTofu documentation](https://opentofu.org/docs/) — language reference
- [Azure Provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) — resource reference
- [Kubernetes recommended labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/) — labeling standard followed by `common/k8s-labels`
- [Azure Workload Identity](https://azure.github.io/azure-workload-identity/docs/) — the OIDC federation pattern used by `azure/aks`
