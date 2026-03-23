# azure/storage

Reusable OpenTofu module that provisions an Azure Storage Account (Blob) with a private endpoint and private DNS zone. Designed as the "Golden Path" for secure blob storage across all Arxen tenants.

## Security Defaults

The following settings are hardcoded and cannot be overridden by callers:

| Setting | Value | Rationale |
|---|---|---|
| `https_traffic_only_enabled` | `true` | Reject all unencrypted traffic |
| `min_tls_version` | `TLS1_2` | Prohibit legacy TLS 1.0/1.1 |
| `public_network_access_enabled` | `false` | No public internet access; access via private endpoint only |
| Blob versioning | `enabled` | Protects against accidental overwrites and deletions |

A private endpoint (`pep-st-<short_tenant>`) is always created and wired to a module-managed private DNS zone (`privatelink.blob.core.windows.net`), ensuring the storage account is only reachable from within the VNet.

## Storage Account Naming

Azure Storage Account names must be **3-24 characters, lowercase alphanumeric only** (no hyphens or underscores).

Auto-generated name pattern: `<environment>st<first-8-chars-of-tenant-id>` with hyphens stripped.

Example: `environment = "dev"`, `tenant_id = "12345678-..."` → `devst12345678` (13 chars).

Use `name_override` to supply a custom name when needed — validation enforces the Azure naming constraint.

## Usage

```hcl
module "vnet" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/vnet?ref=v0.1.0"

  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = var.resource_group_name
}

module "storage" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/storage?ref=v0.1.0"

  tenant_id                  = var.tenant_id
  environment                = var.environment
  location                   = var.location
  resource_group_name        = var.resource_group_name
  private_endpoint_subnet_id = module.vnet.private_endpoints_subnet_id
  vnet_id                    = module.vnet.vnet_id

  # Optional overrides
  account_tier             = "Standard"
  account_replication_type = "GRS"   # Recommended for stage/prod
  tags                     = { cost_center = "platform" }
}

# Consumed by ai-workspace module
module "ai_workspace" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/ai-workspace?ref=v0.1.0"

  storage_account_id = module.storage.account_id
  # ...
}
```

## Inputs

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| `tenant_id` | `string` | — | yes | Arxen tenant identifier (UUID). Used in resource naming and tagging. |
| `environment` | `string` | — | yes | Deployment environment: `dev`, `stage`, or `prod`. |
| `location` | `string` | — | yes | Azure region to deploy resources into. |
| `resource_group_name` | `string` | — | yes | Name of the resource group to deploy into. |
| `private_endpoint_subnet_id` | `string` | — | yes | Subnet ID for the private endpoint (use `azure/vnet` `private_endpoints_subnet_id` output). |
| `vnet_id` | `string` | — | yes | VNet ID for the private DNS zone link (use `azure/vnet` `vnet_id` output). |
| `tags` | `map(string)` | `{}` | no | Additional tags merged with default module tags. |
| `name_override` | `string` | `null` | no | Override auto-generated storage account name. Must be 3-24 lowercase alphanumeric chars. |
| `account_tier` | `string` | `"Standard"` | no | Performance tier: `Standard` or `Premium`. |
| `account_replication_type` | `string` | `"LRS"` | no | Replication type: `LRS`, `ZRS`, `GRS`, `GZRS`, `RAGRS`, or `RAGZRS`. Use `GRS`/`GZRS` for stage/prod. |

## Outputs

| Name | Sensitive | Description |
|---|---|---|
| `resource_id` | no | ARM resource ID of the Storage Account. |
| `resource_name` | no | Provisioned name of the Storage Account. |
| `account_id` | no | ARM resource ID of the Storage Account (ergonomic alias for `resource_id`; used by `ai-workspace` module). |
| `primary_blob_endpoint` | no | Primary blob service endpoint URL. |
| `primary_access_key` | **yes** | Primary storage account access key. **Never log or display this value.** Store in Key Vault and reference via secret. |

> `primary_access_key` is marked `sensitive = true`. OpenTofu will redact it in plan/apply output, but callers must take care not to expose it in logs or state outputs. Prefer Managed Identity / RBAC-based access over key-based access wherever possible.
