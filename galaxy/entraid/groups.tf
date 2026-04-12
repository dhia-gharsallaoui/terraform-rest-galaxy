# ── Entra ID Groups ───────────────────────────────────────────────────────────

variable "entraid_groups" {
  type = map(object({
    display_name                     = string
    mail_enabled                     = bool
    mail_nickname                    = string
    security_enabled                 = bool
    description                      = optional(string, null)
    group_types                      = optional(list(string), null)
    visibility                       = optional(string, null)
    is_assignable_to_role            = optional(bool, null)
    membership_rule                  = optional(string, null)
    membership_rule_processing_state = optional(string, null)
  }))
  description = <<-EOT
    Map of Entra ID groups to create via Microsoft Graph API.
    Each map key acts as the for_each identifier.

    Requires var.graph_access_token to be set with a token scoped to
    https://graph.microsoft.com/.default.

    Example:
      entraid_groups = {
        admins = {
          display_name     = "Platform Admins"
          mail_enabled     = false
          mail_nickname    = "platform-admins"
          security_enabled = true
        }
      }
  EOT
  default     = {}
}

locals {
  entraid_groups = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.entraid_groups, {}), var.entraid_groups)
  )
  _entraid_grp_ctx = provider::rest::merge_with_outputs(local.entraid_groups, module.entraid_groups)
}

module "entraid_groups" {
  source   = "./modules/entraid/group"
  for_each = local.entraid_groups

  providers = {
    rest = rest.graph
  }

  display_name                     = each.value.display_name
  mail_enabled                     = each.value.mail_enabled
  mail_nickname                    = each.value.mail_nickname
  security_enabled                 = each.value.security_enabled
  description                      = try(each.value.description, null)
  group_types                      = try(each.value.group_types, null)
  visibility                       = try(each.value.visibility, null)
  is_assignable_to_role            = try(each.value.is_assignable_to_role, null)
  membership_rule                  = try(each.value.membership_rule, null)
  membership_rule_processing_state = try(each.value.membership_rule_processing_state, null)
}
