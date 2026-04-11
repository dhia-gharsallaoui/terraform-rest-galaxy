# ── Azure Arc Connected Clusters ──────────────────────────────────────────────

variable "azure_arc_connected_clusters" {
  type = map(object({
    subscription_id                = string
    resource_group_name            = string
    cluster_name                   = string
    location                       = optional(string, null)
    identity_type                  = optional(string, "SystemAssigned")
    agent_public_key_certificate   = optional(string, "")
    kind                           = optional(string, null)
    distribution                   = optional(string, null)
    distribution_version           = optional(string, null)
    infrastructure                 = optional(string, null)
    private_link_state             = optional(string, null)
    private_link_scope_resource_id = optional(string, null)
    azure_hybrid_benefit           = optional(string, null)
    aad_profile = optional(object({
      enable_azure_rbac      = optional(bool, false)
      admin_group_object_ids = optional(list(string), [])
      tenant_id              = optional(string, null)
    }), null)
    arc_agent_profile = optional(object({
      desired_agent_version = optional(string, null)
      agent_auto_upgrade    = optional(string, "Enabled")
    }), null)
    tags                = optional(map(string), null)
    _tenant             = optional(string, null)
    wait_for_connection = optional(bool, true)
  }))
  description = <<-EOT
    Map of Azure Arc connected clusters to register. Each map key acts as the
    for_each identifier.

    Example:
      azure_arc_connected_clusters = {
        platform = {
          subscription_id              = "00000000-..."
          resource_group_name          = "rg-arc"
          cluster_name                 = "platform-cluster"
          location                     = "westeurope"
          agent_public_key_certificate = "<base64-encoded-public-key>"
          distribution                 = "kind"
          aad_profile = {
            enable_azure_rbac      = true
            admin_group_object_ids = ["00000000-..."]
          }
        }
      }
  EOT
  default     = {}
}

locals {
  azure_arc_connected_clusters = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_arc_connected_clusters, {}), var.azure_arc_connected_clusters)
  )
  _arc_cc_ctx = provider::rest::merge_with_outputs(local.azure_arc_connected_clusters, module.azure_arc_connected_clusters)
}

# Creates Azure Arc connected cluster ARM resources via the REST API.
# The Arc agents are installed via helm_releases (rest_helm_release)
# after the ARM resource is provisioned. The public key comes from
# tls_private_keys via ref: resolution in the YAML config.
module "azure_arc_connected_clusters" {
  source   = "./modules/azure/arc_connected_cluster"
  for_each = local.azure_arc_connected_clusters

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations, module.k8s_kind_clusters, module.entraid_groups]

  subscription_id                = try(each.value.subscription_id, var.subscription_id)
  resource_group_name            = each.value.resource_group_name
  cluster_name                   = each.value.cluster_name
  location                       = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  agent_public_key_certificate   = try(each.value.agent_public_key_certificate, "")
  identity_type                  = try(each.value.identity_type, "SystemAssigned")
  kind                           = try(each.value.kind, null)
  distribution                   = try(each.value.distribution, null)
  distribution_version           = try(each.value.distribution_version, null)
  infrastructure                 = try(each.value.infrastructure, null)
  private_link_state             = try(each.value.private_link_state, null)
  private_link_scope_resource_id = try(each.value.private_link_scope_resource_id, null)
  azure_hybrid_benefit           = try(each.value.azure_hybrid_benefit, null)
  aad_profile                    = try(each.value.aad_profile, null)
  arc_agent_profile              = try(each.value.arc_agent_profile, null)
  tags                           = try(each.value.tags, null)
  wait_for_connection            = try(each.value.wait_for_connection, true)

  auth_ref = try(each.value._tenant, null)
}
