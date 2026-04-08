# azure/observability

Provisions an **Azure Log Analytics Workspace** and an **Azure Monitor Application Insights** instance as the central observability stack for an Arxen tenant environment. The workspace-based Application Insights instance stores all telemetry in the Log Analytics Workspace, enabling unified log queries across infrastructure and application layers. Outputs are consumed by downstream modules (`azure/aks` and `azure/ai-workspace`).

## Usage

```hcl
module "observability" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/observability?ref=v0.1.0"

  tenant_id           = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  environment         = "prod"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.main.name

  retention_in_days = 90

  # Application Insights is enabled by default. Disable for infra-only stacks.
  application_insights_enabled = true
  application_insights_type    = "web"

  tags = {
    cost_center = "platform"
    team        = "infra"
  }
}

# Pass workspace_id to the AKS module
module "aks" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/aks?ref=v0.1.0"

  log_analytics_workspace_id = module.observability.workspace_id
  # ...
}

# Pass connection string to an application via Key Vault (never plaintext)
resource "azurerm_key_vault_secret" "appi_connection_string" {
  name         = "appi-connection-string"
  value        = module.observability.application_insights_connection_string
  key_vault_id = module.keyvault.vault_id
}
```

## Resource Naming

When `name_override` is not set, the workspace is named using the pattern:

```
<environment>-log-<first-8-chars-of-tenant-id>
```

For example, tenant `a1b2c3d4-...` in `prod` becomes `prod-log-a1b2c3d4`.

## Inputs

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| `tenant_id` | `string` | — | yes | Arxen tenant identifier (internal UUID). Used for tagging and naming. |
| `environment` | `string` | — | yes | Deployment environment: `dev`, `stage`, or `prod`. |
| `location` | `string` | — | yes | Azure region to deploy resources into. |
| `resource_group_name` | `string` | — | yes | Name of the resource group to deploy into. |
| `tags` | `map(string)` | `{}` | no | Additional tags to merge with default module tags. |
| `name_override` | `string` | `null` | no | Override the auto-generated resource name. |
| `retention_in_days` | `number` | `30` | no | Number of days to retain logs in the workspace. |
| `sku` | `string` | `"PerGB2018"` | no | Log Analytics Workspace SKU. |
| `application_insights_enabled` | `bool` | `true` | no | Whether to provision Application Insights backed by the workspace. |
| `application_insights_type` | `string` | `"web"` | no | Application Insights type: `web`, `other`, `java`, `Node.JS`, `MobileCenter`. |

## Outputs

| Name | Sensitive | Description |
|---|---|---|
| `resource_id` | no | ARM resource ID of the Log Analytics Workspace. |
| `resource_name` | no | Name of the Log Analytics Workspace as provisioned. |
| `workspace_id` | no | Workspace ID (GUID) used by AKS OMS agent and `azurerm_monitor_diagnostic_setting` resources. |
| `application_insights_id` | no | ARM resource ID of the Application Insights instance. `null` when disabled. |
| `application_insights_instrumentation_key` | **yes** | Instrumentation key. Do not store in plaintext — write to Key Vault. |
| `application_insights_connection_string` | **yes** | Connection string. Do not store in plaintext — write to Key Vault. |

## Default Tags

Every resource created by this module receives the following tags automatically:

| Tag | Value |
|---|---|
| `tenant_id` | Value of `var.tenant_id` |
| `environment` | Value of `var.environment` |
| `managed_by` | `opentofu` |
| `module` | `arxen-infra-module/azure/observability` |

Caller-supplied `tags` are merged on top and may override defaults.

## Notes

- No `backend` or `provider` blocks are defined — those are the caller's responsibility.
- The `workspace_id` output is the GUID used by `azurerm_kubernetes_cluster.oms_agent` and all `azurerm_monitor_diagnostic_setting` resources.
- The `resource_id` output is used by the `azure/ai-workspace` module for its diagnostics sink.
