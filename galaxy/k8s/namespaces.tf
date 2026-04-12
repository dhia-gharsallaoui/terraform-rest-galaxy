# ── Kubernetes Namespaces ─────────────────────────────────────────────────────

variable "k8s_namespaces" {
  type = map(object({
    cluster     = string
    name        = string
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
  }))
  description = <<-EOT
    Map of Kubernetes namespaces to create via the K8s REST API.
    The 'cluster' field references a k8s_kind_clusters key name to determine
    which kube-apiserver to target.

    Example:
      k8s_namespaces = {
        monitoring = {
          cluster = "ref:k8s_kind_clusters.platform.name"
          name    = "monitoring"
          labels  = { managed-by = "terraform-rest" }
        }
      }
  EOT
  default     = {}
}

locals {
  k8s_namespaces = provider::rest::resolve_map(
    local._k8s_ctx_l0,
    merge(try(local._yaml_raw.k8s_namespaces, {}), var.k8s_namespaces)
  )
  _k8s_ns_ctx = provider::rest::merge_with_outputs(local.k8s_namespaces, module.k8s_namespaces)
}

# import {
#   for_each = { for k, v in local.k8s_namespaces : k => v if contains(local._k8s_available_clusters, v.cluster) }
#   to = module.k8s_namespaces[each.key].rest_resource.namespace
#   id = jsonencode({
#     id   = "${local._k8s_cluster_creds_by_name[each.value.cluster].endpoint}/api/v1/namespaces/${each.value.name}"
#     path = "${local._k8s_cluster_creds_by_name[each.value.cluster].endpoint}/api/v1/namespaces"
#     header = {
#       Authorization = "Bearer ${local._k8s_cluster_creds_by_name[each.value.cluster].token}"
#     }
#     body = {
#       apiVersion = null
#       kind       = null
#       metadata   = null
#     }
#   })
# }

module "k8s_namespaces" {
  source   = "./modules/k8s/namespace"
  for_each = { for k, v in local.k8s_namespaces : k => v if contains(local._k8s_available_clusters, v.cluster) }

  providers = {
    rest = rest.k8s
  }

  cluster_endpoint = local._k8s_cluster_creds_by_name[each.value.cluster].endpoint
  cluster_token    = local._k8s_cluster_creds_by_name[each.value.cluster].token
  name             = each.value.name
  labels           = try(each.value.labels, {})
  annotations      = try(each.value.annotations, {})
}
