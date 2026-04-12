# ── Helm Releases ─────────────────────────────────────────────────────────────

variable "helm_releases" {
  type = map(object({
    cluster                  = string
    name                     = string
    namespace                = optional(string, "default")
    chart                    = string
    repository               = optional(string, null)
    chart_version            = optional(string, null)
    values                   = optional(string, null)
    set                      = optional(map(string), {})
    set_sensitive            = optional(map(string), {})
    kubeconfig_path          = optional(string, null)
    kube_context             = optional(string, null)
    create_namespace         = optional(bool, true)
    wait                     = optional(bool, true)
    timeout                  = optional(number, 600)
    insecure_skip_tls_verify = optional(bool, false)
    # Maps Helm set_sensitive keys to tls_private_keys YAML keys.
    # Each entry injects tls_private_key.this[value].private_key_pem
    # into set_sensitive under the given key name.
    _tls_key_refs = optional(map(string), {})
  }))
  description = <<-EOT
    Map of Helm releases to install on Kubernetes clusters.
    The 'cluster' field references a k8s_kind_clusters key name to determine
    which kube context to use (derived as "kind-<cluster_name>").

    Example:
      helm_releases = {
        arc_agent_platform = {
          cluster    = "ref:k8s_kind_clusters.platform.name"
          name       = "azure-arc"
          namespace  = "azure-arc"
          chart      = "azure-arc"
          repository = "https://azurearcfork8s.azurecr.io/helm/v1/repo"
          set = {
            "global.subscriptionId" = "00000000-..."
            "global.resourceGroupName" = "rg-arc"
            "global.clusterName"       = "platform-cluster"
          }
        }
      }
  EOT
  default     = {}
}

locals {
  helm_releases = provider::rest::resolve_map(
    local._k8s_ctx_l2,
    merge(try(local._yaml_raw.helm_releases, {}), var.helm_releases)
  )
  _helm_rel_ctx = provider::rest::merge_with_outputs(local.helm_releases, module.helm_releases)
}

module "helm_releases" {
  source   = "./modules/k8s/helm_release"
  for_each = local.helm_releases

  depends_on = [module.k8s_kind_clusters, module.azure_arc_connected_clusters, module.azure_container_registry_imports]

  name          = each.value.name
  namespace     = try(each.value.namespace, "default")
  chart         = each.value.chart
  repository    = try(each.value.repository, null)
  chart_version = try(each.value.chart_version, null)
  values        = try(each.value.values, null)
  set           = try(each.value.set, {})
  set_sensitive = merge(
    try(each.value.set_sensitive, {}),
    { for k, ref in try(each.value._tls_key_refs, {}) : k => tls_private_key.this[ref].private_key_pem }
  )
  kubeconfig_path          = try(each.value.kubeconfig_path, null)
  kube_context             = try(each.value.kube_context, "kind-${each.value.cluster}")
  create_namespace         = try(each.value.create_namespace, true)
  wait                     = try(each.value.wait, true)
  timeout                  = try(each.value.timeout, 600)
  insecure_skip_tls_verify = try(each.value.insecure_skip_tls_verify, false)
}
