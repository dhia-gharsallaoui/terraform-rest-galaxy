# ── Kind Clusters ─────────────────────────────────────────────────────────────

variable "k8s_kind_clusters" {
  type = map(object({
    name               = string
    kubernetes_version = string
    networking = optional(object({
      api_server_port = optional(number, 6443)
      pod_subnet      = optional(string, null)
      service_subnet  = optional(string, null)
    }), {})
    node_pools = optional(map(object({
      role   = string
      count  = optional(number, 1)
      labels = optional(map(string), {})
      taints = optional(list(object({
        key    = string
        value  = optional(string, "")
        effect = string
      })), [])
    })), {})
  }))
  description = <<-EOT
    Map of kind clusters to create locally. Each map key acts as the for_each
    identifier and must be unique within this configuration.

    Example:
      k8s_kind_clusters = {
        platform = {
          name               = "platform-cluster"
          kubernetes_version = "1.30.2"
          node_pools = {
            control_plane = { role = "control-plane", count = 1 }
            workers       = { role = "worker", count = 3 }
          }
        }
      }
  EOT
  default     = {}
}

locals {
  k8s_kind_clusters = provider::rest::resolve_map(
    local._ctx_l0,
    merge(try(local._yaml_raw.k8s_kind_clusters, {}), var.k8s_kind_clusters)
  )
  # Build context with only non-sensitive outputs to avoid tainting
  # the entire layer context (kubeconfig, client_key, etc. are sensitive).
  _k8s_kind_ctx = {
    for k, v in local.k8s_kind_clusters : k => merge(v, {
      name               = try(module.k8s_kind_clusters[k].name, v.name)
      endpoint           = try(module.k8s_kind_clusters[k].endpoint, null)
      kubernetes_version = try(module.k8s_kind_clusters[k].kubernetes_version, v.kubernetes_version)
    })
  }
}

module "k8s_kind_clusters" {
  source   = "./modules/k8s/kind_cluster"
  for_each = local.k8s_kind_clusters

  name               = each.value.name
  kubernetes_version = each.value.kubernetes_version
  networking         = try(each.value.networking, {})
  node_pools         = try(each.value.node_pools, {})
  docker_available   = var.docker_available
}
