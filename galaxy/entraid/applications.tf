# ── Entra ID Applications ─────────────────────────────────────────────────────

variable "entraid_applications" {
  type = map(object({
    display_name                  = string
    sign_in_audience              = optional(string, "AzureADMyOrg")
    description                   = optional(string, null)
    notes                         = optional(string, null)
    identifier_uris               = optional(list(string), null)
    tags                          = optional(list(string), null)
    group_membership_claims       = optional(string, null)
    is_fallback_public_client     = optional(bool, false)
    is_device_only_auth_supported = optional(bool, null)
    web = optional(object({
      redirect_uris                = optional(list(string), null)
      home_page_url                = optional(string, null)
      logout_url                   = optional(string, null)
      implicit_grant_access_tokens = optional(bool, false)
      implicit_grant_id_tokens     = optional(bool, false)
    }), null)
    spa = optional(object({
      redirect_uris = list(string)
    }), null)
    public_client = optional(object({
      redirect_uris = list(string)
    }), null)
    api = optional(object({
      requested_access_token_version = optional(number, 2)
      oauth2_permission_scopes = optional(list(object({
        admin_consent_description  = string
        admin_consent_display_name = string
        id                         = string
        is_enabled                 = optional(bool, true)
        type                       = optional(string, "User")
        user_consent_description   = optional(string, null)
        user_consent_display_name  = optional(string, null)
        value                      = string
      })), null)
    }), null)
    required_resource_access = optional(list(object({
      resource_app_id = string
      resource_access = list(object({
        id   = string
        type = string
      }))
    })), null)
    app_roles = optional(list(object({
      allowed_member_types = list(string)
      description          = string
      display_name         = string
      id                   = string
      is_enabled           = optional(bool, true)
      value                = optional(string, null)
    })), null)
    optional_claims = optional(object({
      access_token = optional(list(object({
        name                  = string
        additional_properties = optional(list(string), null)
        essential             = optional(bool, false)
        source                = optional(string, null)
      })), null)
      id_token = optional(list(object({
        name                  = string
        additional_properties = optional(list(string), null)
        essential             = optional(bool, false)
        source                = optional(string, null)
      })), null)
      saml2_token = optional(list(object({
        name                  = string
        additional_properties = optional(list(string), null)
        essential             = optional(bool, false)
        source                = optional(string, null)
      })), null)
    }), null)
  }))
  description = <<-EOT
    Map of Entra ID application registrations to create via Microsoft Graph API.
    Each map key acts as the for_each identifier.

    Requires var.graph_access_token to be set with a token scoped to
    https://graph.microsoft.com/.default.

    Example:
      entraid_applications = {
        my_app = {
          display_name     = "my-application"
          sign_in_audience = "AzureADMyOrg"
          web = {
            redirect_uris = ["https://myapp.example.com/auth/callback"]
          }
        }
      }
  EOT
  default     = {}
}

locals {
  entraid_applications = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.entraid_applications, {}), var.entraid_applications)
  )
  _entraid_app_ctx = provider::rest::merge_with_outputs(local.entraid_applications, module.entraid_applications)
}

module "entraid_applications" {
  source   = "./modules/entraid/application"
  for_each = local.entraid_applications

  providers = {
    rest = rest.graph
  }

  display_name                  = each.value.display_name
  sign_in_audience              = try(each.value.sign_in_audience, "AzureADMyOrg")
  description                   = try(each.value.description, null)
  notes                         = try(each.value.notes, null)
  identifier_uris               = try(each.value.identifier_uris, null)
  tags                          = try(each.value.tags, null)
  group_membership_claims       = try(each.value.group_membership_claims, null)
  is_fallback_public_client     = try(each.value.is_fallback_public_client, false)
  is_device_only_auth_supported = try(each.value.is_device_only_auth_supported, null)
  web                           = try(each.value.web, null)
  spa                           = try(each.value.spa, null)
  public_client                 = try(each.value.public_client, null)
  api                           = try(each.value.api, null)
  required_resource_access      = try(each.value.required_resource_access, null)
  app_roles                     = try(each.value.app_roles, null)
  optional_claims               = try(each.value.optional_claims, null)
}
