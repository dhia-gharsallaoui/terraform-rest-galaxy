# ── Kubernetes ClusterRoleBindings ────────────────────────────────────────────

variable "k8s_cluster_role_bindings" {
  type = map(object({
    cluster = string
    name    = string
    role_ref = object({
      kind      = string
      name      = string
      api_group = optional(string, "rbac.authorization.k8s.io")
    })
    subjects = list(object({
      kind      = string
      name      = string
      api_group = optional(string, "rbac.authorization.k8s.io")
      namespace = optional(string, null)
    }))
    labels = optional(map(string), {})
  }))
  description = <<-EOT
    Map of Kubernetes ClusterRoleBindings to create via the K8s REST API.

    Example:
      k8s_cluster_role_bindings = {
        admin_binding = {
          cluster = "ref:k8s_kind_clusters.platform.name"
          name    = "entra-id-admins"
          role_ref = { kind = "ClusterRole", name = "cluster-admin" }
          subjects = [{ kind = "Group", name = "00000000-..." }]
        }
      }
  EOT
  default     = {}
}

locals {
  k8s_cluster_role_bindings = provider::rest::resolve_map(
    local._k8s_ctx_l0,
    merge(try(local._yaml_raw.k8s_cluster_role_bindings, {}), var.k8s_cluster_role_bindings)
  )
  _k8s_crb_ctx = provider::rest::merge_with_outputs(local.k8s_cluster_role_bindings, module.k8s_cluster_role_bindings)
}

module "k8s_cluster_role_bindings" {
  source   = "./modules/k8s/cluster_role_binding"
  for_each = { for k, v in local.k8s_cluster_role_bindings : k => v if contains(local._k8s_available_clusters, v.cluster) }

  providers = {
    rest = rest.k8s
  }

  depends_on = [module.entraid_groups]

  cluster_endpoint = local._k8s_cluster_creds_by_name[each.value.cluster].endpoint
  cluster_token    = local._k8s_cluster_creds_by_name[each.value.cluster].token
  name             = each.value.name
  role_ref         = each.value.role_ref
  subjects         = each.value.subjects
  labels           = try(each.value.labels, {})
}
