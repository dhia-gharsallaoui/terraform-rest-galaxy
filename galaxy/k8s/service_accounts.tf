# ── Kubernetes Service Accounts ───────────────────────────────────────────────

variable "k8s_service_accounts" {
  type = map(object({
    cluster     = string
    namespace   = string
    name        = string
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
  }))
  description = <<-EOT
    Map of Kubernetes ServiceAccounts to create via the K8s REST API.
    The 'cluster' field references a cluster name to determine
    which kube-apiserver to target.

    Example:
      k8s_service_accounts = {
        my_app = {
          cluster   = "aks-regulated-001"
          namespace = "ref:k8s_namespaces.my_app.name"
          name      = "my-app-sa"
          annotations = {
            "azure.workload.identity/client-id" = "..."
          }
          labels = {
            "azure.workload.identity/use" = "true"
          }
        }
      }
  EOT
  default     = {}
}

locals {
  k8s_service_accounts = provider::rest::resolve_map(
    local._k8s_ctx_l0a,
    merge(try(local._yaml_raw.k8s_service_accounts, {}), var.k8s_service_accounts)
  )
  _k8s_sa_ctx = provider::rest::merge_with_outputs(local.k8s_service_accounts, module.k8s_service_accounts)
}

# import {
#   for_each = { for k, v in local.k8s_service_accounts : k => v if contains(local._k8s_available_clusters, v.cluster) }
#   to = module.k8s_service_accounts[each.key].rest_resource.service_account
#   id = jsonencode({
#     id   = "${local._k8s_cluster_creds_by_name[each.value.cluster].endpoint}/api/v1/namespaces/${each.value.namespace}/serviceaccounts/${each.value.name}"
#     path = "${local._k8s_cluster_creds_by_name[each.value.cluster].endpoint}/api/v1/namespaces/${each.value.namespace}/serviceaccounts"
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

module "k8s_service_accounts" {
  source   = "./modules/k8s/service_account"
  for_each = { for k, v in local.k8s_service_accounts : k => v if contains(local._k8s_available_clusters, v.cluster) }

  providers = {
    rest = rest.k8s
  }

  depends_on = [module.k8s_namespaces]

  cluster_endpoint = local._k8s_cluster_creds_by_name[each.value.cluster].endpoint
  cluster_token    = local._k8s_cluster_creds_by_name[each.value.cluster].token
  name             = each.value.name
  namespace        = each.value.namespace
  labels           = try(each.value.labels, {})
  annotations      = try(each.value.annotations, {})
}
