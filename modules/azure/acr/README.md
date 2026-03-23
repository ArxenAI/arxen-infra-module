# azure/acr

Provisions a private Azure Container Registry (ACR) with Premium SKU, a private endpoint, a private DNS zone, and a virtual network link. This module implements the Arxen golden path for container image storage — public access is disabled by design and cannot be opted in.

## Security Defaults

| Control | Value | Rationale |
|---|---|---|
| SKU | `Premium` | Hardcoded. Required for private endpoint support. |
| `admin_enabled` | `false` | Admin credentials are a static-secret anti-pattern; use managed identity or service principal RBAC. |
| `public_network_access_enabled` | `false` | All pull/push traffic must traverse the private endpoint; no public internet exposure. |
| Private DNS zone | `privatelink.azurecr.io` | Ensures clients inside the VNet resolve the registry to its private IP. |

Geo-replication is available via the `georeplications` variable and is recommended for `stage` and `prod` environments to improve pull latency and resilience.

## ACR Naming Constraint

Azure Container Registry names must be **5–50 characters, alphanumeric only** — no hyphens, underscores, or special characters. The module automatically strips hyphens from the generated name:

```
name_raw = "${environment}acr${substr(tenant_id, 0, 8)}"
# e.g. "devacr1a2b3c4d"
name     = replace(name_raw, "-", "")
```

If you supply `name_override`, **you are responsible** for ensuring it meets ACR naming rules. The module does not validate the override value against Azure's naming constraints.

## Usage

```hcl
module "acr" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/acr?ref=v0.1.0"

  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  # Wire in from the azure/vnet module
  private_endpoint_subnet_id = module.vnet.private_endpoints_subnet_id
  vnet_id                    = module.vnet.vnet_id

  # Optional: geo-replicate for prod
  georeplications = var.environment == "prod" ? [
    {
      location                = "westeurope"
      zone_redundancy_enabled = true
    }
  ] : []

  tags = {
    team    = "platform"
    cost_center = "infra"
  }
}

# Consumed by the ai-workspace module:
# container_registry_id = module.acr.registry_id
```

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `tenant_id` | `string` | yes | Arxen tenant UUID. Used in resource naming and tagging. |
| `environment` | `string` | yes | Deployment environment: `dev`, `stage`, or `prod`. |
| `location` | `string` | yes | Azure region to deploy resources into. |
| `resource_group_name` | `string` | yes | Name of the resource group to deploy into. |
| `private_endpoint_subnet_id` | `string` | yes | Subnet ID for the ACR private endpoint. Use `azure/vnet` `private_endpoints_subnet_id` output. |
| `vnet_id` | `string` | yes | VNet ID for the private DNS zone virtual network link. Use `azure/vnet` `vnet_id` output. |
| `tags` | `map(string)` | no | Additional tags merged with default module tags. Default: `{}`. |
| `name_override` | `string` | no | Override the auto-generated ACR name. Caller must comply with ACR naming rules. Default: `null`. |
| `georeplications` | `list(object)` | no | Geo-replication locations (Premium SKU only). Default: `[]`. |

### `georeplications` object schema

| Attribute | Type | Default | Description |
|---|---|---|---|
| `location` | `string` | required | Azure region for the replica. |
| `zone_redundancy_enabled` | `bool` | `false` | Enable zone redundancy for the replica. |

## Outputs

| Name | Description | Sensitive |
|---|---|---|
| `resource_id` | ARM resource ID of the Container Registry. | false |
| `resource_name` | Name of the Container Registry as provisioned. | false |
| `registry_id` | ARM resource ID of the Container Registry (ergonomic alias for `resource_id`). | false |
| `login_server` | Login server FQDN (e.g. `<name>.azurecr.io`). | false |

## Resources Created

| Resource | Purpose |
|---|---|
| `azurerm_container_registry.main` | The Container Registry itself. |
| `azurerm_private_dns_zone.acr` | Private DNS zone `privatelink.azurecr.io`. |
| `azurerm_private_dns_zone_virtual_network_link.acr` | Links the DNS zone to the VNet so resolution works. |
| `azurerm_private_endpoint.acr` | Private endpoint in the designated subnet. |
