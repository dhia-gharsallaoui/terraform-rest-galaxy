# ── Entra ID OAuth2 Permission Grants (Admin Consent) ─────────────────────────

variable "entraid_oauth2_permission_grants" {
  type = map(object({
    client_id    = string
    resource_id  = string
    scope        = optional(string, "user_impersonation")
    consent_type = optional(string, "AllPrincipals")
    principal_id = optional(string, null)
  }))
  description = <<-EOT
    Map of OAuth2 delegated permission grants (admin consent) to create via
    Microsoft Graph beta API. This is the programmatic equivalent of clicking
    "Grant administrator consent" in the Azure Portal.

    Uses the /beta endpoint which supports both user and service principal
    callers (required for pipeline/automation scenarios).

    Requires var.graph_access_token to be set with a token scoped to
    https://graph.microsoft.com/.default.

    Example:
      entraid_oauth2_permission_grants = {
        vpn_client_consent = {
          client_id   = "ref:entraid_service_principals.vpn_client.id"
          resource_id = "ref:entraid_service_principals.vpn_server.id"
          scope       = "user_impersonation"
        }
      }
  EOT
  default     = {}
}

locals {
  entraid_oauth2_permission_grants = provider::rest::resolve_map(
    local._entraid_ctx_l1,
    merge(try(local._yaml_raw.entraid_oauth2_permission_grants, {}), var.entraid_oauth2_permission_grants)
  )
  _entraid_opg_ctx = provider::rest::merge_with_outputs(local.entraid_oauth2_permission_grants, module.entraid_oauth2_permission_grants)
}

module "entraid_oauth2_permission_grants" {
  source   = "./modules/entraid/oauth2_permission_grant"
  for_each = local.entraid_oauth2_permission_grants

  providers = {
    rest = rest.graph
  }

  client_id    = each.value.client_id
  resource_id  = each.value.resource_id
  scope        = try(each.value.scope, "user_impersonation")
  consent_type = try(each.value.consent_type, "AllPrincipals")
  principal_id = try(each.value.principal_id, null)

  depends_on = [
    module.entraid_service_principals,
  ]
}
