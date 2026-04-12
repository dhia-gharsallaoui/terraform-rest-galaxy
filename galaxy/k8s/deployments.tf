# ── Kubernetes Deployments ────────────────────────────────────────────────────

variable "k8s_deployments" {
  type = map(object({
    cluster       = string
    namespace     = string
    name          = string
    image         = string
    replicas      = optional(number, 1)
    labels        = optional(map(string), {})
    node_selector = optional(map(string), {})
    tolerations = optional(list(object({
      key      = string
      operator = optional(string, "Equal")
      value    = optional(string, null)
      effect   = optional(string, null)
    })), [])
    container_port       = optional(number, null)
    env                  = optional(map(string), {})
    service_account_name = optional(string, null)
    pod_labels           = optional(map(string), {})
    command              = optional(list(string), null)
    args                 = optional(list(string), null)
  }))
  description = <<-EOT
    Map of Kubernetes Deployments to create via the K8s REST API.

    Example:
      k8s_deployments = {
        nginx = {
          cluster   = "ref:k8s_kind_clusters.platform.name"
          namespace = "ref:k8s_namespaces.workloads.name"
          name      = "nginx"
          image     = "nginx:latest"
          replicas  = 2
        }
      }
  EOT
  default     = {}
}

locals {
  k8s_deployments = provider::rest::resolve_map(
    local._k8s_ctx_l1,
    merge(try(local._yaml_raw.k8s_deployments, {}), var.k8s_deployments)
  )
  _k8s_dep_ctx = provider::rest::merge_with_outputs(local.k8s_deployments, module.k8s_deployments)
}

module "k8s_deployments" {
  source   = "./modules/k8s/deployment"
  for_each = { for k, v in local.k8s_deployments : k => v if contains(local._k8s_available_clusters, v.cluster) }

  providers = {
    rest = rest.k8s
  }

  depends_on = [module.k8s_namespaces, module.k8s_service_accounts]

  cluster_endpoint     = local._k8s_cluster_creds_by_name[each.value.cluster].endpoint
  cluster_token        = local._k8s_cluster_creds_by_name[each.value.cluster].token
  name                 = each.value.name
  namespace            = each.value.namespace
  image                = each.value.image
  replicas             = try(each.value.replicas, 1)
  labels               = try(each.value.labels, {})
  node_selector        = try(each.value.node_selector, {})
  tolerations          = try(each.value.tolerations, [])
  container_port       = try(each.value.container_port, null)
  env                  = try(each.value.env, {})
  service_account_name = try(each.value.service_account_name, null)
  pod_labels           = try(each.value.pod_labels, {})
  command              = try(each.value.command, null)
  args                 = try(each.value.args, null)
}
