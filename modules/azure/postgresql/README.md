# azure/postgresql

Deploys an Azure PostgreSQL Flexible Server into a delegated subnet with no public access.
Part of the Arxen golden-path module library.

## Security Defaults

These settings are **non-overridable** by design:

| Control | Value | Rationale |
|---|---|---|
| Public access | Disabled | `delegated_subnet_id` is required; no public endpoint is exposed |
| Backup retention | 35 days | SPEC.md mandate — hardcoded in `main.tf`, not a variable |
| SSL enforcement | Always on | Azure PostgreSQL Flexible Server enforces SSL by default; cannot be disabled |
| Private DNS | Required | Caller must supply `private_dns_zone_id` — module does not create the DNS zone |

## Private DNS Zone Requirement

Azure requires a private DNS zone named **`privatelink.postgres.database.azure.com`** to resolve the
server's FQDN within the VNet. There can only be one such zone per VNet link.

**The caller is responsible for:**
1. Creating the `privatelink.postgres.database.azure.com` private DNS zone.
2. Linking it to the VNet that contains the delegated subnet.
3. Passing the resulting zone resource ID as `private_dns_zone_id`.

If you use the `azure/vnet` module from this library, it can output the delegated subnet ID.
The DNS zone itself must be created separately (e.g., via `azurerm_private_dns_zone` +
`azurerm_private_dns_zone_virtual_network_link`) before calling this module.

## Usage Example

```hcl
resource "azurerm_private_dns_zone" "psql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "psql" {
  name                  = "psql-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.psql.name
  virtual_network_id    = module.vnet.vnet_id
}

module "postgresql" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/postgresql?ref=v0.2.0"

  tenant_id           = var.tenant_id
  environment         = "prod"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.main.name

  delegated_subnet_id = module.vnet.postgresql_delegated_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.psql.id

  administrator_login    = "psqladmin"
  administrator_password = var.postgresql_admin_password  # sourced from Key Vault or secret manager

  sku_name                     = "GP_Standard_D4s_v3"
  storage_mb                   = 65536
  postgresql_version           = "16"
  geo_redundant_backup_enabled = true  # recommended for prod
  zone                         = "1"

  tags = {
    cost_center = "platform"
    team        = "infra"
  }
}
```

## Inputs

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| `tenant_id` | `string` | — | yes | Arxen tenant UUID. Used in resource naming and tagging. |
| `environment` | `string` | — | yes | Deployment environment: `dev`, `stage`, or `prod`. |
| `location` | `string` | — | yes | Azure region to deploy resources into. |
| `resource_group_name` | `string` | — | yes | Name of the resource group to deploy into. |
| `delegated_subnet_id` | `string` | — | yes | Subnet ID with `Microsoft.DBforPostgreSQL/flexibleServers` delegation. |
| `private_dns_zone_id` | `string` | — | yes | Private DNS zone resource ID (`privatelink.postgres.database.azure.com`). |
| `administrator_login` | `string` | — | yes | PostgreSQL administrator username. |
| `administrator_password` | `string` | — | yes | PostgreSQL administrator password. Marked sensitive — pass via secret manager. |
| `tags` | `map(string)` | `{}` | no | Additional tags merged with default module tags. |
| `name_override` | `string` | `null` | no | Override the auto-generated server name (`<env>-psql-<short-tenant-id>`). |
| `sku_name` | `string` | `"GP_Standard_D2s_v3"` | no | Compute SKU (e.g., `GP_Standard_D2s_v3`, `B_Standard_B1ms`). |
| `storage_mb` | `number` | `32768` | no | Storage size in MB. Range: 32768 (32 GB) to 16777216 (16 TB). |
| `postgresql_version` | `string` | `"15"` | no | PostgreSQL major version: `14`, `15`, or `16`. |
| `geo_redundant_backup_enabled` | `bool` | `false` | no | Enable geo-redundant backups. Recommended for `stage` and `prod`. |
| `zone` | `string` | `"1"` | no | Availability zone for the primary server: `1`, `2`, or `3`. |

## Outputs

| Name | Sensitive | Description |
|---|---|---|
| `resource_id` | no | ARM resource ID of the PostgreSQL Flexible Server. |
| `resource_name` | no | Name of the PostgreSQL Flexible Server as provisioned. |
| `server_id` | no | Alias for `resource_id` — ergonomic shorthand. |
| `fqdn` | no | Fully-qualified domain name (FQDN) of the server. |
| `connection_string` | **yes** | PostgreSQL connection string. Store securely; never log. |
