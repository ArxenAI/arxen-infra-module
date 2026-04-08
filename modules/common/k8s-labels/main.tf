locals {
  # Standard Arxen labels following Kubernetes recommended label conventions.
  # https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/
  standard_labels = {
    "app.kubernetes.io/managed-by" = "opentofu"
    "app.kubernetes.io/component"  = var.component
    "app.kubernetes.io/part-of"    = var.part_of
    "arxen.io/tenant-id"           = var.tenant_id
    "arxen.io/environment"         = var.environment
  }

  # version label is omitted when empty to avoid polluting labels with a meaningless value.
  version_label = var.version != "" ? { "app.kubernetes.io/version" = var.version } : {}

  # Caller labels are merged last so they can add context, but they cannot override
  # the arxen.io/* or app.kubernetes.io/managed-by keys (those are computed last).
  merged = merge(var.extra_labels, local.version_label, local.standard_labels)
}
