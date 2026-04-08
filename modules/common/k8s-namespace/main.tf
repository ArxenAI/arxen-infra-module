locals {
  default_labels = {
    "app.kubernetes.io/managed-by" = "opentofu"
    "arxen.io/tenant-id"           = var.tenant_id
    "arxen.io/environment"         = var.environment
    "arxen.io/module"              = "arxen-infra-module/common/k8s-namespace"
  }
  labels = merge(local.default_labels, var.labels)
}

resource "kubernetes_namespace" "main" {
  metadata {
    name   = var.name
    labels = local.labels
    annotations = {
      "arxen.io/tenant-id"   = var.tenant_id
      "arxen.io/environment" = var.environment
    }
  }
}

# Default-deny all ingress — pods in this namespace accept no inbound traffic unless
# explicitly allowed by an additional NetworkPolicy. All workloads start locked down.
resource "kubernetes_network_policy" "default_deny_ingress" {
  metadata {
    name      = "default-deny-ingress"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

# Default-deny all egress — optional. Enable for workloads that must not initiate
# outbound connections. DNS (UDP/TCP 53) is always permitted so name resolution works.
resource "kubernetes_network_policy" "default_deny_egress" {
  count = var.deny_egress ? 1 : 0

  metadata {
    name      = "default-deny-egress"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    # Always allow egress DNS so pods can resolve service names.
    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

# RoleBindings for viewer groups — read-only access to all resources in the namespace.
resource "kubernetes_role_binding" "viewers" {
  for_each = toset(var.viewer_groups)

  metadata {
    name      = "viewer-${replace(each.key, ":", "-")}"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }

  subject {
    kind      = "Group"
    name      = each.key
    api_group = "rbac.authorization.k8s.io"
  }
}

# RoleBindings for editor groups — read/write access to all resources in the namespace,
# excluding RBAC management (no role/rolebinding mutations).
resource "kubernetes_role_binding" "editors" {
  for_each = toset(var.editor_groups)

  metadata {
    name      = "editor-${replace(each.key, ":", "-")}"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }

  subject {
    kind      = "Group"
    name      = each.key
    api_group = "rbac.authorization.k8s.io"
  }
}
