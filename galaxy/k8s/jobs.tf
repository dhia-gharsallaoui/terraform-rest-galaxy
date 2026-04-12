# ── Kubernetes Jobs ───────────────────────────────────────────────────────────

variable "k8s_jobs" {
  type = map(object({
    cluster              = string
    namespace            = string
    name                 = string
    image                = string
    backoff_limit        = optional(number, 0)
    labels               = optional(map(string), {})
    pod_labels           = optional(map(string), {})
    env                  = optional(map(string), {})
    service_account_name = optional(string, null)
    command              = optional(list(string), null)
    args                 = optional(list(string), null)
  }))
  description = <<-EOT
    Map of Kubernetes Jobs to create via the K8s REST API.
    Jobs run to completion — Terraform waits until the Job succeeds (or fails).
    Use for post-deployment verification tests.

    Example:
      k8s_jobs = {
        e2e_postgres = {
          cluster   = "aks-regulated-001"
          namespace = "ref:k8s_namespaces.test_app.name"
          name      = "e2e-postgres-test"
          image     = "mcr.microsoft.com/azure-cli:2.84.0"
          command   = ["/bin/bash", "-c"]
          args      = ["echo OK"]
        }
      }
  EOT
  default     = {}
}

locals {
  k8s_jobs = provider::rest::resolve_map(
    local._k8s_ctx_l1,
    merge(try(local._yaml_raw.k8s_jobs, {}), var.k8s_jobs)
  )
  _k8s_job_ctx = provider::rest::merge_with_outputs(local.k8s_jobs, module.k8s_jobs)
}

# import {
#   for_each = { for k, v in local.k8s_jobs : k => v if contains(local._k8s_available_clusters, v.cluster) }
#   to = module.k8s_jobs[each.key].rest_resource.job
#   id = jsonencode({
#     id   = "${local._k8s_cluster_creds_by_name[each.value.cluster].endpoint}/apis/batch/v1/namespaces/${each.value.namespace}/jobs/${each.value.name}"
#     path = "${local._k8s_cluster_creds_by_name[each.value.cluster].endpoint}/apis/batch/v1/namespaces/${each.value.namespace}/jobs"
#     header = {
#       Authorization = "Bearer ${local._k8s_cluster_creds_by_name[each.value.cluster].token}"
#     }
#     body = {
#       apiVersion = null
#       kind       = null
#       metadata   = null
#       spec       = null
#     }
#   })
# }

module "k8s_jobs" {
  source   = "./modules/k8s/job"
  for_each = { for k, v in local.k8s_jobs : k => v if contains(local._k8s_available_clusters, v.cluster) }

  providers = {
    rest = rest.k8s
  }

  depends_on = [module.k8s_namespaces, module.k8s_service_accounts, module.k8s_deployments]

  cluster_endpoint     = local._k8s_cluster_creds_by_name[each.value.cluster].endpoint
  cluster_token        = local._k8s_cluster_creds_by_name[each.value.cluster].token
  name                 = each.value.name
  namespace            = each.value.namespace
  image                = each.value.image
  backoff_limit        = try(each.value.backoff_limit, 0)
  labels               = try(each.value.labels, {})
  pod_labels           = try(each.value.pod_labels, {})
  env                  = try(each.value.env, {})
  service_account_name = try(each.value.service_account_name, null)
  command              = try(each.value.command, null)
  args                 = try(each.value.args, null)
}
