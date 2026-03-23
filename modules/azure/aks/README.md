# azure/aks

Provisions a private Azure Kubernetes Service (AKS) cluster with hardcoded security defaults. This is the compute backbone of the Arxen platform — every security control is non-overridable so that all clusters across dev/stage/prod meet the same baseline.

Consumes outputs from:
- `azure/vnet` — provides the node subnet via `aks_nodes_subnet_id`
- `azure/observability` — provides the Log Analytics Workspace via `resource_id`

---

## Security Defaults

All settings in the table below are hardcoded in `main.tf` and cannot be changed via variables. They exist to enforce SPEC.md requirements across every environment.

| Setting | Value | Note |
|---|---|---|
| `private_cluster_enabled` | `true` | API server is not reachable from the public internet |
| `azure_policy_enabled` | `true` | Enforces Kyverno/OPA policies at the admission controller level |
| `oidc_issuer_enabled` | `true` | Required for Workload Identity federation |
| `workload_identity_enabled` | `true` | Pods authenticate to Azure services without static credentials |
| `network_plugin` | `"azure"` | Azure CNI for full VNet integration and pod-level NSG enforcement |
| `network_policy` | `"calico"` | Fine-grained pod-to-pod network policy enforcement |
| `role_based_access_control_enabled` | `true` | Kubernetes RBAC is always on |
| `local_account_disabled` | `true` | No static `kubectl` credentials — AAD-only access enforced |
| `identity.type` | `"SystemAssigned"` | Cluster uses a managed identity; no service principal or static key |
| `msi_auth_for_monitoring_enabled` | `true` | OMS agent authenticates via managed identity — no static workspace key |
| `os_disk_type` | `"Ephemeral"` | Reduces attack surface; node state is not persisted across reboots |

---

## Usage

The example below wires the `vnet` and `observability` modules to `aks` using module outputs, matching the golden path pattern.

```hcl
module "vnet" {
  source              = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/vnet?ref=v0.1.0"
  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

module "observability" {
  source              = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/observability?ref=v0.1.0"
  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

module "aks" {
  source              = "git::https://github.com/arxen/arxen-infra-module.git//modules/azure/aks?ref=v0.1.0"
  tenant_id           = var.tenant_id
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subscription_id     = var.subscription_id
  azure_ad_tenant_id  = var.azure_ad_tenant_id

  kubernetes_version = "1.30"
  node_count         = 3
  node_vm_size       = "Standard_D4s_v5"

  # Wire vnet and observability outputs
  vnet_subnet_id             = module.vnet.aks_nodes_subnet_id
  log_analytics_workspace_id = module.observability.resource_id

  admin_group_object_ids = [var.platform_admins_group_id]

  tags = {
    team = "platform"
  }
}
```

---

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `tenant_id` | `string` | yes | — | Arxen tenant identifier (UUID). Used in resource naming and tagging. |
| `environment` | `string` | yes | — | Deployment environment: `dev`, `stage`, or `prod`. |
| `location` | `string` | yes | — | Azure region to deploy the AKS cluster into. |
| `resource_group_name` | `string` | yes | — | Name of the resource group to deploy into. |
| `subscription_id` | `string` | yes | — | Azure subscription ID for the cluster. |
| `kubernetes_version` | `string` | yes | — | Kubernetes version (e.g., `1.29`, `1.30`). |
| `vnet_subnet_id` | `string` | yes | — | Subnet ID for AKS nodes. Use `azure/vnet` `aks_nodes_subnet_id` output. |
| `log_analytics_workspace_id` | `string` | yes | — | Log Analytics Workspace resource ID. Use `azure/observability` `resource_id` output. |
| `azure_ad_tenant_id` | `string` | yes | — | Azure AD tenant ID for AKS RBAC integration. |
| `node_count` | `number` | no | `2` | Initial number of nodes in the default node pool (1–100). |
| `node_vm_size` | `string` | no | `"Standard_D4s_v5"` | Azure VM SKU for the default node pool. |
| `admin_group_object_ids` | `list(string)` | no | `[]` | Azure AD group object IDs granted cluster admin role. |
| `name_override` | `string` | no | `null` | Override the auto-generated cluster name. |
| `tags` | `map(string)` | no | `{}` | Additional tags merged with module defaults. |

---

## Outputs

| Name | Sensitive | Description |
|---|---|---|
| `resource_id` | no | ARM resource ID of the AKS cluster. |
| `resource_name` | no | Name of the AKS cluster as provisioned. |
| `cluster_id` | no | Alias for `resource_id`. |
| `cluster_name` | no | Alias for `resource_name`. |
| `kube_config` | **yes** | Raw kubeconfig. Do not store in plaintext. |
| `oidc_issuer_url` | no | OIDC issuer URL for Workload Identity federation. |
| `kubelet_identity_object_id` | no | Object ID of the kubelet managed identity. Use to assign ACR pull permissions. |
| `node_resource_group` | no | Name of the auto-created `MC_` resource group. |

---

## Workload Identity

With `oidc_issuer_enabled = true` and `workload_identity_enabled = true`, pods can federate with Azure AD using the OIDC issuer URL rather than mounting service account tokens or static credentials.

To wire a workload identity:

1. Create a User-Assigned Managed Identity in Azure.
2. Create a Federated Identity Credential on that identity, pointing to:
   - **Issuer:** `module.aks.oidc_issuer_url`
   - **Subject:** `system:serviceaccount:<namespace>:<service-account-name>`
3. Annotate the Kubernetes ServiceAccount: `azure.workload.identity/client-id: <client-id>`.
4. Label the pod: `azure.workload.identity/use: "true"`.

No static credentials are stored anywhere in this flow.

---

## ACR Pull Access

The kubelet managed identity (`kubelet_identity_object_id`) must be granted `AcrPull` on any Azure Container Registry the cluster needs to pull images from:

```hcl
resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.acr.resource_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}
```

This replaces the legacy `--attach-acr` flag and keeps all access grants as code.
