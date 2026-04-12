# ── Kubernetes ConfigMaps ─────────────────────────────────────────────────────

variable "k8s_config_maps" {
  type = map(object({
    cluster   = string
    namespace = string
    name      = string
    data      = optional(map(string), {})
    labels    = optional(map(string), {})
  }))
  description = <<-EOT
    Map of Kubernetes ConfigMaps to create via the K8s REST API.

    Example:
      k8s_config_maps = {
        app_config = {
          cluster   = "ref:k8s_kind_clusters.platform.name"
          namespace = "ref:k8s_namespaces.workloads.name"
          name      = "app-settings"
          data      = { LOG_LEVEL = "info" }
        }
      }
  EOT
  default     = {}
}

locals {
  k8s_config_maps = provider::rest::resolve_map(
    local._k8s_ctx_l1,
    merge(try(local._yaml_raw.k8s_config_maps, {}), var.k8s_config_maps)
  )
  _k8s_cm_ctx = provider::rest::merge_with_outputs(local.k8s_config_maps, module.k8s_config_maps)
}

module "k8s_config_maps" {
  source   = "./modules/k8s/config_map"
  for_each = { for k, v in local.k8s_config_maps : k => v if contains(local._k8s_available_clusters, v.cluster) }

  providers = {
    rest = rest.k8s
  }

  depends_on = [module.k8s_namespaces]

  cluster_endpoint = local._k8s_cluster_creds_by_name[each.value.cluster].endpoint
  cluster_token    = local._k8s_cluster_creds_by_name[each.value.cluster].token
  name             = each.value.name
  namespace        = each.value.namespace
  data             = try(each.value.data, {})
  labels           = try(each.value.labels, {})
}
