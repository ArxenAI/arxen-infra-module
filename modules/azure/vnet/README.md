# azure/vnet

Provisions the network foundation for an Arxen tenant on Azure. Creates a Virtual Network with four purpose-built subnets and an NSG attached to each, providing a default-deny inbound posture from day one.

## Usage

```hcl
module "vnet" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/vnet?ref=v0.1.0"

  tenant_id           = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  environment         = "dev"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.main.name

  # Optional: override default CIDRs if the tenant address space differs
  address_space          = ["10.10.0.0/16"]
  aks_nodes_cidr         = "10.10.0.0/22"
  aks_pods_cidr          = "10.10.4.0/22"
  private_endpoints_cidr = "10.10.8.0/24"

  # Optional: enable Application Gateway subnet
  enable_appgw_subnet = true
  appgw_cidr          = "10.10.9.0/24"

  tags = {
    cost_center = "platform"
    owner       = "infra-team"
  }
}

# Consume outputs in downstream modules
module "aks" {
  source          = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/aks?ref=v0.1.0"
  node_subnet_id  = module.vnet.aks_nodes_subnet_id
  # ...
}

module "keyvault" {
  source                    = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/keyvault?ref=v0.1.0"
  private_endpoint_subnet_id = module.vnet.private_endpoints_subnet_id
  # ...
}
```

## Inputs

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| `tenant_id` | `string` | — | yes | Arxen tenant identifier (internal UUID). Used for tagging and naming. |
| `environment` | `string` | — | yes | Deployment environment: `dev`, `stage`, or `prod`. |
| `location` | `string` | — | yes | Azure region to deploy resources into. |
| `resource_group_name` | `string` | — | yes | Name of the resource group to deploy into. |
| `tags` | `map(string)` | `{}` | no | Additional tags to merge with default module tags. |
| `name_override` | `string` | `null` | no | Override the auto-generated VNet name. |
| `address_space` | `list(string)` | `["10.0.0.0/16"]` | no | Address space for the Virtual Network. |
| `aks_nodes_cidr` | `string` | `"10.0.0.0/22"` | no | CIDR for the AKS node pool subnet. |
| `aks_pods_cidr` | `string` | `"10.0.4.0/22"` | no | CIDR for the AKS pod subnet (CNI overlay). |
| `private_endpoints_cidr` | `string` | `"10.0.8.0/24"` | no | CIDR for the private endpoints subnet. |
| `appgw_cidr` | `string` | `"10.0.9.0/24"` | no | CIDR for the Application Gateway subnet. |
| `enable_appgw_subnet` | `bool` | `false` | no | Whether to provision the Application Gateway subnet and NSG. |

## Outputs

| Name | Description |
|---|---|
| `resource_id` | The ARM resource ID of the Virtual Network. |
| `resource_name` | The name of the Virtual Network as provisioned. |
| `vnet_id` | The ARM resource ID of the Virtual Network (alias for `resource_id`). |
| `aks_nodes_subnet_id` | Subnet ID for the AKS node pool. |
| `aks_pods_subnet_id` | Subnet ID for the AKS pod CIDR (CNI). |
| `private_endpoints_subnet_id` | Subnet ID for private endpoints. |
| `appgw_subnet_id` | Subnet ID for the Application Gateway. Empty string if `enable_appgw_subnet` is `false`. |

## Security Notes

### NSGs on every subnet

Every subnet created by this module has a dedicated Network Security Group associated with it. Azure's default NSG rules deny all inbound internet traffic that is not explicitly permitted. No custom allow rules are added by this module — the expectation is that rules are layered on by the consuming stack (e.g., AKS adds its own rules via the AKS resource provider).

### Private endpoint network policies disabled

The `snet-private-endpoints` subnet is created with `private_endpoint_network_policies_enabled = false`. This is required by Azure for private endpoints to function correctly; NSG rules are enforced at the NIC level by the private endpoint resource itself rather than at the subnet policy level.

### No hardcoded CIDRs or regions

All network ranges and the target Azure region are passed in as variables. The defaults are safe starting points for a single-tenant `/16` but must be overridden when deploying into an existing, pre-allocated address space to avoid conflicts.

### Auto-generated naming

The VNet name defaults to `{environment}-vnet-{first 8 chars of tenant_id}`, providing consistent, conflict-free naming across environments without requiring the caller to manage names manually. Use `name_override` only when integrating with an existing naming convention.
