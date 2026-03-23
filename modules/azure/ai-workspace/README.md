# azure/ai-workspace

Provisions an Azure Machine Learning Workspace, wiring together Key Vault, Storage Account, Container Registry, and optionally Application Insights. This module is a Golden Path component of the Arxen platform and is the final dependency in the Azure module chain — it must be called after `azure/keyvault`, `azure/storage`, and `azure/acr` are provisioned.

## Dependencies

This module requires outputs from three other Arxen modules before it can be applied:

| Module | Output used | Variable |
|---|---|---|
| `azure/keyvault` | `vault_id` | `key_vault_id` |
| `azure/storage` | `account_id` | `storage_account_id` |
| `azure/acr` | `registry_id` | `container_registry_id` |
| _(optional)_ caller-managed `azurerm_application_insights` | `.id` | `application_insights_id` |

Application Insights integration is optional — set `application_insights_id = null` (the default) to omit it. The `azure/observability` module does not directly expose an Application Insights resource ID; if you need monitoring, create an `azurerm_application_insights` resource in your live stack and pass its `.id`.

## Security Defaults

| Setting | Default | Notes |
|---|---|---|
| `public_network_access_enabled` | `false` | Private-only by default; opt-in via variable |
| Identity | `SystemAssigned` | Managed identity always enabled; no service principal credentials required |

Public network access is disabled by default. For production environments this value must remain `false`. Set to `true` only for development/testing where a private endpoint is not yet available.

The workspace identity is `SystemAssigned`. After provisioning, grant the workspace's principal ID appropriate Azure RBAC roles on the Key Vault, Storage Account, and Container Registry as needed by your workloads.

## Usage

```hcl
module "keyvault" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/keyvault?ref=v0.1.0"

  tenant_id                  = var.tenant_id
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  azure_ad_tenant_id         = data.azurerm_client_config.current.tenant_id
  private_endpoint_subnet_id = module.vnet.private_endpoints_subnet_id
  vnet_id                    = module.vnet.vnet_id
}

module "storage" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/storage?ref=v0.1.0"

  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

module "acr" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/acr?ref=v0.1.0"

  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

# Optional: Application Insights for workspace monitoring
resource "azurerm_application_insights" "ml" {
  name                = "${var.environment}-mlws-appinsights"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

module "ai_workspace" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/ai-workspace?ref=v0.1.0"

  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  # Wire in dependency module outputs
  key_vault_id          = module.keyvault.vault_id
  storage_account_id    = module.storage.account_id
  container_registry_id = module.acr.registry_id

  # Optional Application Insights — omit or set null to skip
  application_insights_id = azurerm_application_insights.ml.id

  tags = {
    cost_center = "ml-platform"
    team        = "data-science"
  }
}
```

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `tenant_id` | `string` | yes | — | Arxen tenant identifier (internal UUID). Used for tagging and naming. |
| `environment` | `string` | yes | — | Deployment environment: `dev`, `stage`, or `prod`. |
| `location` | `string` | yes | — | Azure region to deploy resources into. |
| `resource_group_name` | `string` | yes | — | Name of the resource group to deploy into. |
| `key_vault_id` | `string` | yes | — | Key Vault resource ID for workspace secret storage (use `azure/keyvault` `vault_id` output). |
| `storage_account_id` | `string` | yes | — | Storage Account resource ID for workspace artifact storage (use `azure/storage` `account_id` output). |
| `container_registry_id` | `string` | yes | — | Container Registry resource ID for Docker image management (use `azure/acr` `registry_id` output). |
| `application_insights_id` | `string` | no | `null` | Application Insights resource ID for workspace monitoring. Set to `null` to skip. |
| `public_network_access_enabled` | `bool` | no | `false` | Whether to enable public network access. Must be `false` for production. |
| `image_build_compute_name` | `string` | no | `null` | Name of the compute target for image builds. |
| `name_override` | `string` | no | `null` | Override the auto-generated workspace name. |
| `tags` | `map(string)` | no | `{}` | Additional tags to merge with default module tags. |

## Outputs

| Name | Description | Sensitive |
|---|---|---|
| `resource_id` | The ARM resource ID of the Azure ML Workspace. | false |
| `resource_name` | The name of the Azure ML Workspace as provisioned. | false |
| `workspace_id` | Alias for `resource_id` — ergonomic alias for downstream references. | false |
| `discovery_url` | The workspace discovery URL used by Azure ML SDK clients. | false |

## Resource Naming

When `name_override` is not set, the workspace name is auto-generated as:

```
${environment}-mlws-${substr(tenant_id, 0, 8)}
```

Example: `dev-mlws-a1b2c3d4`.

## Resources Created

| Resource | Purpose |
|---|---|
| `azurerm_machine_learning_workspace.main` | The Azure ML Workspace instance |
