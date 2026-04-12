# ── Entra ID Service Principals ────────────────────────────────────────────────

variable "entraid_service_principals" {
  type = map(object({
    app_id = string
  }))
  description = <<-EOT
    Map of service principals to register in the tenant via Microsoft Graph API.
    Creates Enterprise Application registrations from well-known application
    (client) IDs. This is the programmatic equivalent of "az ad sp create".

    Requires var.graph_access_token to be set with a token scoped to
    https://graph.microsoft.com/.default.

    Example:
      entraid_service_principals = {
        azure_vpn = {
          app_id = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8"
        }
      }
  EOT
  default     = {}
}

locals {
  entraid_service_principals = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.entraid_service_principals, {}), var.entraid_service_principals)
  )
  _entraid_sp_ctx = provider::rest::merge_with_outputs(local.entraid_service_principals, module.entraid_service_principals)
}

module "entraid_service_principals" {
  source   = "./modules/entraid/service_principal"
  for_each = local.entraid_service_principals

  providers = {
    rest = rest.graph
  }

  app_id = each.value.app_id
}
