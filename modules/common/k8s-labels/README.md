# common/k8s-labels

Utility module that produces a standardized Kubernetes label map following the [Kubernetes recommended labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/) convention, extended with Arxen-specific labels.

This module has **no cloud resources** — it is a pure computation module. It ensures every Deployment, Service, ConfigMap, and other resource in the platform carries a consistent, queryable label set regardless of which team created it.

---

## Usage

```hcl
module "labels" {
  source = "git::https://github.com/arxen/arxen-infra-module.git//modules/common/k8s-labels?ref=v0.1.0"

  tenant_id   = var.tenant_id
  environment = var.environment
  component   = "api"
  part_of     = "arxen-api"
  version     = "1.4.2"
}

resource "kubernetes_deployment" "api" {
  metadata {
    name      = "arxen-api"
    namespace = module.namespace.resource_name
    labels    = module.labels.labels
  }

  spec {
    template {
      metadata {
        labels = module.labels.labels
      }
      # ...
    }
  }
}
```

---

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `tenant_id` | `string` | yes | — | Arxen tenant identifier (UUID). |
| `environment` | `string` | yes | — | Deployment environment: `dev`, `stage`, or `prod`. |
| `component` | `string` | yes | — | Component name (e.g., `api`, `worker`). Maps to `app.kubernetes.io/component`. |
| `part_of` | `string` | yes | — | Parent application name (e.g., `arxen-api`). Maps to `app.kubernetes.io/part-of`. |
| `version` | `string` | no | `""` | Component version (e.g., `1.2.3`). Omitted from output when empty. |
| `extra_labels` | `map(string)` | no | `{}` | Additional labels merged before standard labels. Cannot override `arxen.io/*` or `app.kubernetes.io/managed-by`. |

---

## Outputs

| Name | Sensitive | Description |
|---|---|---|
| `resource_id` | no | Always `null` — no cloud resource is provisioned. |
| `resource_name` | no | Always `null` — no cloud resource is provisioned. |
| `labels` | no | Full standardized label map. Pass to `metadata.labels` on any Kubernetes resource. |

---

## Label Schema

| Key | Source | Example |
|---|---|---|
| `app.kubernetes.io/managed-by` | hardcoded | `opentofu` |
| `app.kubernetes.io/component` | `var.component` | `api` |
| `app.kubernetes.io/part-of` | `var.part_of` | `arxen-api` |
| `app.kubernetes.io/version` | `var.version` | `1.4.2` (omitted when empty) |
| `arxen.io/tenant-id` | `var.tenant_id` | `550e8400-...` |
| `arxen.io/environment` | `var.environment` | `prod` |

Caller-supplied `extra_labels` are merged before the standard keys, so standard keys always win.
