# ── Entra ID Group Members ────────────────────────────────────────────────────

variable "entraid_group_members" {
  type = map(object({
    group_id  = string
    member_id = string
  }))
  description = <<-EOT
    Map of Entra ID group membership links to create via Microsoft Graph API.
    Each map key acts as the for_each identifier.

    Requires var.graph_access_token to be set with a token scoped to
    https://graph.microsoft.com/.default.

    Example:
      entraid_group_members = {
        jane_in_admins = {
          group_id  = "ref:entraid_groups.admins.id"
          member_id = "ref:entraid_users.jane.id"
        }
      }
  EOT
  default     = {}
}

locals {
  entraid_group_members = provider::rest::resolve_map(
    local._entraid_ctx_l0,
    merge(try(local._yaml_raw.entraid_group_members, {}), var.entraid_group_members)
  )
  _entraid_gm_ctx = provider::rest::merge_with_outputs(local.entraid_group_members, module.entraid_group_members)
}

module "entraid_group_members" {
  source   = "./modules/entraid/group_member"
  for_each = local.entraid_group_members

  providers = {
    rest = rest.graph
  }

  group_id  = each.value.group_id
  member_id = each.value.member_id

  depends_on = [
    module.entraid_groups,
    module.entraid_users,
  ]
}
