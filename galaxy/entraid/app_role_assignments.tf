# ── Entra ID App Role Assignments ─────────────────────────────────────────────

variable "entraid_app_role_assignments" {
  type = map(object({
    resource_app_id = string
    principal_id    = string
    app_role_id     = optional(string, "00000000-0000-0000-0000-000000000000")
  }))
  description = <<-EOT
    Map of app role assignments to create via Microsoft Graph API.
    Assigns a user, group, or service principal to an Enterprise Application
    (service principal).

    Requires var.graph_access_token to be set with a token scoped to
    https://graph.microsoft.com/.default.

    Example:
      entraid_app_role_assignments = {
        vpn_users_to_vpn_app = {
          resource_app_id = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8"   # Azure VPN Enterprise App
          principal_id    = "ref:entraid_groups.vpn_users.id"
        }
      }
  EOT
  default     = {}
}

locals {
  entraid_app_role_assignments = provider::rest::resolve_map(
    local._entraid_ctx_l1,
    merge(try(local._yaml_raw.entraid_app_role_assignments, {}), var.entraid_app_role_assignments)
  )
  _entraid_ara_ctx = provider::rest::merge_with_outputs(local.entraid_app_role_assignments, module.entraid_app_role_assignments)
}

module "entraid_app_role_assignments" {
  source   = "./modules/entraid/app_role_assignment"
  for_each = local.entraid_app_role_assignments

  providers = {
    rest = rest.graph
  }

  resource_app_id = each.value.resource_app_id
  principal_id    = each.value.principal_id
  app_role_id     = try(each.value.app_role_id, "00000000-0000-0000-0000-000000000000")

  depends_on = [
    module.entraid_groups,
    module.entraid_users,
  ]
}
