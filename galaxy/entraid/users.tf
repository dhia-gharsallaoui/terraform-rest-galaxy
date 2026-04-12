# ── Entra ID Users ────────────────────────────────────────────────────────────

variable "entraid_users" {
  type = map(object({
    display_name        = string
    mail_nickname       = string
    user_principal_name = string
    account_enabled     = bool
    password_profile = object({
      password                                    = string
      force_change_password_next_sign_in          = optional(bool, true)
      force_change_password_next_sign_in_with_mfa = optional(bool, false)
    })
    given_name         = optional(string, null)
    surname            = optional(string, null)
    job_title          = optional(string, null)
    department         = optional(string, null)
    office_location    = optional(string, null)
    city               = optional(string, null)
    country            = optional(string, null)
    state              = optional(string, null)
    postal_code        = optional(string, null)
    street_address     = optional(string, null)
    company_name       = optional(string, null)
    mobile_phone       = optional(string, null)
    preferred_language = optional(string, null)
    usage_location     = optional(string, null)
    user_type          = optional(string, null)
    employee_id        = optional(string, null)
    employee_type      = optional(string, null)
    other_mails        = optional(list(string), null)
  }))
  description = <<-EOT
    Map of Entra ID users to create via Microsoft Graph API.
    Each map key acts as the for_each identifier.

    Requires var.graph_access_token to be set with a token scoped to
    https://graph.microsoft.com/.default.

    Example:
      entraid_users = {
        jane = {
          display_name        = "Jane Doe"
          mail_nickname       = "janedoe"
          user_principal_name = "janedoe@contoso.onmicrosoft.com"
          account_enabled     = true
          password_profile = {
            password                           = "SecureP@ss123!"
            force_change_password_next_sign_in = true
          }
        }
      }
  EOT
  default     = {}
}

locals {
  entraid_users = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.entraid_users, {}), var.entraid_users)
  )
  _entraid_usr_ctx = provider::rest::merge_with_outputs(local.entraid_users, module.entraid_users)
}

module "entraid_users" {
  source   = "./modules/entraid/user"
  for_each = local.entraid_users

  providers = {
    rest = rest.graph
  }

  display_name        = each.value.display_name
  mail_nickname       = each.value.mail_nickname
  user_principal_name = each.value.user_principal_name
  account_enabled     = each.value.account_enabled
  password_profile    = each.value.password_profile
  given_name          = try(each.value.given_name, null)
  surname             = try(each.value.surname, null)
  job_title           = try(each.value.job_title, null)
  department          = try(each.value.department, null)
  office_location     = try(each.value.office_location, null)
  city                = try(each.value.city, null)
  country             = try(each.value.country, null)
  state               = try(each.value.state, null)
  postal_code         = try(each.value.postal_code, null)
  street_address      = try(each.value.street_address, null)
  company_name        = try(each.value.company_name, null)
  mobile_phone        = try(each.value.mobile_phone, null)
  preferred_language  = try(each.value.preferred_language, null)
  usage_location      = try(each.value.usage_location, null)
  user_type           = try(each.value.user_type, null)
  employee_id         = try(each.value.employee_id, null)
  employee_type       = try(each.value.employee_type, null)
  other_mails         = try(each.value.other_mails, null)
}
