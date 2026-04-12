# ── User-Assigned Identities ──────────────────────────────────────────────────

variable "azure_user_assigned_identities" {
  type = map(object({
    subscription_id     = string
    resource_group_name = string
    identity_name       = string
    location            = optional(string, null)
    tags                = optional(map(string), null)
    _tenant             = optional(string, null)
  }))
  description = <<-EOT
    Map of user-assigned managed identities to create. Each map key acts as the
    for_each identifier and must be unique within this configuration.

    Example:
      azure_user_assigned_identities = {
        cmk_sa = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-myapp-prod"
          location            = "westeurope"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_user_assigned_identities = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_user_assigned_identities, {}), var.azure_user_assigned_identities)
  )
  _uai_ctx = provider::rest::merge_with_outputs(local.azure_user_assigned_identities, module.azure_user_assigned_identities)
}

module "azure_user_assigned_identities" {
  source   = "./modules/azure/user_assigned_identity"
  for_each = local.azure_user_assigned_identities

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  identity_name       = each.value.identity_name
  location            = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  tags                = try(each.value.tags, null)
  check_existance     = var.check_existance

  # Cross-tenant: if _tenant is set, override the Authorization header
  auth_ref = try(each.value._tenant, null)
}
