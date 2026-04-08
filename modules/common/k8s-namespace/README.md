# common/k8s-namespace

Provisions a Kubernetes Namespace with hardened defaults: a `default-deny-ingress` NetworkPolicy, optional `default-deny-egress` NetworkPolicy with DNS egress exemption, and `viewer`/`editor` RoleBindings wired to the built-in ClusterRoles.

This module is cloud-agnostic and works with any Kubernetes cluster (AKS, EKS, GKE). It is typically consumed alongside `azure/aks` in the same stack.

---

## Security Defaults

| Behavior | Detail |
|---|---|
| Default-deny ingress | All inbound traffic to pods is blocked unless explicitly permitted by an additional NetworkPolicy |
| Optional default-deny egress | When `deny_egress = true`, all outbound traffic is blocked except DNS (UDP/TCP 53) |
| RBAC via built-in ClusterRoles | `viewer_groups` → `view` ClusterRole; `editor_groups` → `edit` ClusterRole — no custom Role definitions |

---

## Usage

```hcl
module "namespace" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/common/k8s-namespace?ref=v0.1.0"

  tenant_id   = var.tenant_id
  environment = var.environment
  name        = "team-payments"

  viewer_groups = ["oidc:payments-readonly"]
  editor_groups = ["oidc:payments-engineers"]

  labels = {
    "arxen.io/team" = "payments"
  }
}
```

To enable egress lockdown for a sensitive workload namespace:

```hcl
module "namespace_restricted" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/common/k8s-namespace?ref=v0.1.0"

  tenant_id   = var.tenant_id
  environment = var.environment
  name        = "team-payments-jobs"
  deny_egress = true
}
```

---

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `tenant_id` | `string` | yes | — | Arxen tenant identifier (UUID). |
| `environment` | `string` | yes | — | Deployment environment: `dev`, `stage`, or `prod`. |
| `name` | `string` | yes | — | Kubernetes namespace name (lowercase, alphanumeric, hyphens). |
| `labels` | `map(string)` | no | `{}` | Additional labels merged with Arxen defaults. |
| `deny_egress` | `bool` | no | `false` | Add a default-deny-egress NetworkPolicy (DNS always permitted). |
| `viewer_groups` | `list(string)` | no | `[]` | Group names bound to the `view` ClusterRole (read-only). |
| `editor_groups` | `list(string)` | no | `[]` | Group names bound to the `edit` ClusterRole (read/write, no RBAC). |

---

## Outputs

| Name | Sensitive | Description |
|---|---|---|
| `resource_id` | no | Kubernetes namespace name (primary identifier). |
| `resource_name` | no | Kubernetes namespace name as provisioned. |
| `labels` | no | Full label map applied to the namespace. |

---

## NetworkPolicy Behavior

Two policies are always created:

1. **`default-deny-ingress`** — drops all ingress traffic to every pod in the namespace. Add separate NetworkPolicy resources to open specific ports/protocols/sources for your workloads.

2. **`default-deny-egress`** (when `deny_egress = true`) — drops all egress except DNS. Required for workloads that must not reach external services.

Both policies use an empty `pod_selector {}` which matches all pods in the namespace.

---

## RBAC

Groups are referenced by name — the exact format depends on your cluster's OIDC/AAD integration. For AKS with Azure AD:

- AAD groups: use the group's Object ID
- OIDC groups: use the format configured in your OIDC provider

```hcl
viewer_groups = ["aad-group-object-id-here"]
editor_groups = ["oidc:my-team@example.com"]
```
