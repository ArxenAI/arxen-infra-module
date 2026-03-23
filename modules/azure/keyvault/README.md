# azure/keyvault

Provisions an Azure Key Vault with hardened security defaults, a private endpoint, and a private DNS zone link. This module is a Golden Path component of the Arxen platform and is consumed by `arxen-infra-live` stacks and the `ai-workspace` module.

## Security Defaults (Non-Overridable)

The following settings are hardcoded and cannot be changed by callers:

| Setting | Value | Reason |
|---|---|---|
| `public_network_access_enabled` | `false` | All access must go through the private endpoint |
| `soft_delete_retention_days` | `90` | Maximum retention for accidental-deletion recovery |
| `purge_protection_enabled` | `true` | Prevents permanent deletion during retention period |
| `enable_rbac_authorization` | `true` | Enforces Azure RBAC instead of legacy access policies |

Access to secrets, keys, and certificates must be granted via Azure RBAC role assignments (e.g. `Key Vault Secrets User`, `Key Vault Secrets Officer`) — vault access policies are disabled.

## Usage

```hcl
module "keyvault" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/keyvault?ref=v0.1.0"

  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  azure_ad_tenant_id  = data.azurerm_client_config.current.tenant_id

  # From azure/vnet module outputs
  private_endpoint_subnet_id = module.vnet.private_endpoints_subnet_id
  vnet_id                    = module.vnet.vnet_id

  sku_name = "standard"

  tags = {
    cost_center = "platform"
  }
}

# Grant access via RBAC (example: allow an app identity to read secrets)
resource "azurerm_role_assignment" "app_secrets_user" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
```

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `tenant_id` | `string` | yes | — | Arxen tenant identifier (internal UUID). Used for tagging and naming. |
| `environment` | `string` | yes | — | Deployment environment: `dev`, `stage`, or `prod`. |
| `location` | `string` | yes | — | Azure region to deploy resources into. |
| `resource_group_name` | `string` | yes | — | Name of the resource group to deploy into. |
| `azure_ad_tenant_id` | `string` | yes | — | Azure Active Directory tenant ID for Key Vault access control. |
| `private_endpoint_subnet_id` | `string` | yes | — | Subnet ID for the Key Vault private endpoint (from `azure/vnet` `private_endpoints_subnet_id` output). |
| `vnet_id` | `string` | yes | — | VNet ID for the private DNS zone virtual network link (from `azure/vnet` `vnet_id` output). |
| `sku_name` | `string` | no | `"standard"` | SKU for the Key Vault: `standard` or `premium`. |
| `name_override` | `string` | no | `null` | Override the auto-generated Key Vault name. Must be 3-24 alphanumeric/hyphen characters and globally unique. |
| `tags` | `map(string)` | no | `{}` | Additional tags to merge with default module tags. |

## Outputs

| Name | Description | Sensitive |
|---|---|---|
| `resource_id` | The ARM resource ID of the Key Vault. | false |
| `resource_name` | The name of the Key Vault as provisioned. | false |
| `vault_id` | Alias for `resource_id` — use this in downstream module `key_vault_id` inputs. | false |
| `vault_uri` | The HTTPS URI of the Key Vault (e.g. `https://<name>.vault.azure.net/`). | false |

## Resource Naming

When `name_override` is not set, the vault name is auto-generated as:

```
${environment}-kv-${substr(tenant_id, 0, 8)}
```

Example: `dev-kv-a1b2c3d4` (16 characters, within the Azure 3-24 character limit).

## Resources Created

| Resource | Purpose |
|---|---|
| `azurerm_key_vault.main` | The Key Vault instance |
| `azurerm_private_dns_zone.keyvault` | Private DNS zone `privatelink.vaultcore.azure.net` |
| `azurerm_private_dns_zone_virtual_network_link.keyvault` | Links the DNS zone to the VNet for name resolution |
| `azurerm_private_endpoint.keyvault` | Private endpoint binding the vault to the private subnet |
