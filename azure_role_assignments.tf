# ── Role Assignments ──────────────────────────────────────────────────────────

variable "azure_role_assignments" {
  type = map(object({
    scope              = string
    role_definition_id = string
    principal_id       = string
    principal_type     = optional(string, "ServicePrincipal")
    description        = optional(string, null)
    condition          = optional(string, null)
    condition_version  = optional(string, null)
    _tenant            = optional(string, null)
  }))
  description = <<-EOT
    Map of role assignments to create. Each map key acts as the for_each identifier.

    Example:
      azure_role_assignments = {
        cmk_sa_crypto_user = {
          scope              = "/subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/my-kv"
          role_definition_id = "/subscriptions/.../providers/Microsoft.Authorization/roleDefinitions/12338..."
          principal_id       = "00000000-0000-0000-0000-000000000000"
          principal_type     = "ServicePrincipal"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_role_assignments = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_role_assignments, {}), var.azure_role_assignments)
  )
  _ra_ctx = provider::rest::merge_with_outputs(local.azure_role_assignments, module.azure_role_assignments)
}

module "azure_role_assignments" {
  source   = "./modules/azure/role_assignment"
  for_each = local.azure_role_assignments

  depends_on = [module.azure_key_vaults, module.azure_user_assigned_identities, module.entraid_groups, module.azure_arc_connected_clusters]

  subscription_id    = try(each.value.subscription_id, var.subscription_id)
  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id
  principal_id       = each.value.principal_id
  principal_type     = try(each.value.principal_type, "ServicePrincipal")
  description        = try(each.value.description, null)
  condition          = try(each.value.condition, null)
  condition_version  = try(each.value.condition_version, null)
  check_existance    = var.check_existance

  # Cross-tenant: if _tenant is set, override the Authorization header
  auth_ref = try(each.value._tenant, null)
}
