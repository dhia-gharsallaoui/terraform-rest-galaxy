# ── Azure Arc Kubernetes Extensions ───────────────────────────────────────────

variable "azure_arc_kubernetes_extensions" {
  type = map(object({
    subscription_id            = optional(string, null)
    resource_group_name        = string
    cluster_rp                 = optional(string, "Microsoft.Kubernetes")
    cluster_resource_name      = optional(string, "connectedClusters")
    cluster_name               = string
    extension_name             = string
    extension_type             = string
    auto_upgrade_minor_version = optional(bool, true)
    release_train              = optional(string, null)
    version_pin                = optional(string, null)
    scope = optional(object({
      cluster = optional(object({
        release_namespace = optional(string, null)
      }), null)
      namespace = optional(object({
        target_namespace = optional(string, null)
      }), null)
    }), null)
    configuration_settings           = optional(map(string), null)
    configuration_protected_settings = optional(map(string), null)
    identity_type                    = optional(string, null)
    plan = optional(object({
      name      = string
      publisher = string
      product   = string
    }), null)
    _tenant = optional(string, null)
  }))
  description = <<-EOT
    Map of Azure Arc Kubernetes extensions to install on connected/managed clusters.

    Example:
      azure_arc_kubernetes_extensions = {
        monitor_edge = {
          resource_group_name = "rg-arc-clusters"
          cluster_name        = "edge-cluster"
          extension_name      = "azuremonitor-pipeline"
          extension_type      = "microsoft.monitor.pipelinecontroller"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_arc_kubernetes_extensions = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_arc_kubernetes_extensions, {}), var.azure_arc_kubernetes_extensions)
  )
  _arc_ext_ctx = provider::rest::merge_with_outputs(local.azure_arc_kubernetes_extensions, module.azure_arc_kubernetes_extensions)

  # Build a map of cluster_name → node architecture by reading the first
  # worker node's kubernetes.io/arch label from the K8s API.
  # All kind clusters share the host machine's architecture.
  _arc_ext_cluster_names = toset([for k, v in local.azure_arc_kubernetes_extensions : v.cluster_name if contains(local._k8s_available_clusters, v.cluster_name)])
}

# ── Auto-detect node architecture per cluster ────────────────────────────────
# Reads the K8s nodes list to extract kubernetes.io/arch from the first node.
# This runs at plan time so the module can block incompatible extensions.
data "rest_resource" "arc_ext_cluster_nodes" {
  provider = rest.k8s
  for_each = local._arc_ext_cluster_names

  id = "${local._k8s_cluster_creds_by_name[each.value].endpoint}/api/v1/nodes?limit=1"

  header = {
    Authorization = "Bearer ${local._k8s_cluster_creds_by_name[each.value].token}"
  }

  output_attrs = toset(["items"])
}

module "azure_arc_kubernetes_extensions" {
  source   = "./modules/azure/arc_kubernetes_extension"
  for_each = local.azure_arc_kubernetes_extensions

  depends_on = [module.azure_arc_connected_clusters]

  subscription_id                  = try(each.value.subscription_id, var.subscription_id)
  resource_group_name              = each.value.resource_group_name
  cluster_rp                       = try(each.value.cluster_rp, "Microsoft.Kubernetes")
  cluster_resource_name            = try(each.value.cluster_resource_name, "connectedClusters")
  cluster_name                     = each.value.cluster_name
  extension_name                   = each.value.extension_name
  extension_type                   = each.value.extension_type
  auto_upgrade_minor_version       = try(each.value.auto_upgrade_minor_version, true)
  release_train                    = try(each.value.release_train, null)
  version_pin                      = try(each.value.version_pin, null)
  scope                            = try(each.value.scope, null)
  configuration_settings           = try(each.value.configuration_settings, null)
  configuration_protected_settings = try(each.value.configuration_protected_settings, null)
  identity_type                    = try(each.value.identity_type, null)
  plan                             = try(each.value.plan, null)
  cluster_node_architecture        = try(data.rest_resource.arc_ext_cluster_nodes[each.value.cluster_name].output.items[0].metadata.labels["kubernetes.io/arch"], null)

  auth_ref = try(each.value._tenant, null)
}
