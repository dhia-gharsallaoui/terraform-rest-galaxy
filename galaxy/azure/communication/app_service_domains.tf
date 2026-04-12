# ── App Service Domains (Domain Registration) ────────────────────────────────

variable "azure_app_service_domains" {
  type = map(object({
    subscription_id     = optional(string)
    resource_group_name = string
    domain_name         = string
    location            = optional(string, "global")
    contact_admin = object({
      first_name    = string
      last_name     = string
      email         = string
      phone         = string
      organization  = optional(string)
      job_title     = optional(string)
      fax           = optional(string)
      middle_name   = optional(string)
      address_line1 = optional(string)
      address_line2 = optional(string)
      city          = optional(string)
      state         = optional(string)
      country       = optional(string)
      postal_code   = optional(string)
    })
    contact_billing = object({
      first_name    = string
      last_name     = string
      email         = string
      phone         = string
      organization  = optional(string)
      job_title     = optional(string)
      fax           = optional(string)
      middle_name   = optional(string)
      address_line1 = optional(string)
      address_line2 = optional(string)
      city          = optional(string)
      state         = optional(string)
      country       = optional(string)
      postal_code   = optional(string)
    })
    contact_registrant = object({
      first_name    = string
      last_name     = string
      email         = string
      phone         = string
      organization  = optional(string)
      job_title     = optional(string)
      fax           = optional(string)
      middle_name   = optional(string)
      address_line1 = optional(string)
      address_line2 = optional(string)
      city          = optional(string)
      state         = optional(string)
      country       = optional(string)
      postal_code   = optional(string)
    })
    contact_tech = object({
      first_name    = string
      last_name     = string
      email         = string
      phone         = string
      organization  = optional(string)
      job_title     = optional(string)
      fax           = optional(string)
      middle_name   = optional(string)
      address_line1 = optional(string)
      address_line2 = optional(string)
      city          = optional(string)
      state         = optional(string)
      country       = optional(string)
      postal_code   = optional(string)
    })
    consent_agreed_by      = string
    consent_agreed_at      = string
    consent_agreement_keys = optional(list(string), [])
    privacy                = optional(bool, true)
    auto_renew             = optional(bool, true)
    dns_type               = optional(string, "AzureDns")
    dns_zone_id            = optional(string, null)
    tags                   = optional(map(string), null)
  }))
  description = <<-EOT
    Map of App Service Domains (domain purchases) to create.

    Example:
      azure_app_service_domains = {
        contoso = {
          resource_group_name = "rg-dns"
          domain_name         = "contoso.com"
          contact_admin       = { first_name = "John", last_name = "Doe", email = "admin@contoso.com", phone = "+1.5551234567" }
          contact_billing     = { first_name = "John", last_name = "Doe", email = "billing@contoso.com", phone = "+1.5551234567" }
          contact_registrant  = { first_name = "John", last_name = "Doe", email = "registrant@contoso.com", phone = "+1.5551234567" }
          contact_tech        = { first_name = "John", last_name = "Doe", email = "tech@contoso.com", phone = "+1.5551234567" }
          consent_agreed_by   = "203.0.113.10"
          consent_agreed_at   = "2026-01-01T00:00:00Z"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_app_service_domains = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_app_service_domains, {}), var.azure_app_service_domains)
  )
  _asd_ctx = provider::rest::merge_with_outputs(local.azure_app_service_domains, module.azure_app_service_domains)
}

module "azure_app_service_domains" {
  source   = "./modules/azure/app_service_domain"
  for_each = local.azure_app_service_domains

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations]

  subscription_id        = try(each.value.subscription_id, var.subscription_id)
  resource_group_name    = each.value.resource_group_name
  domain_name            = each.value.domain_name
  location               = try(each.value.location, "global")
  contact_admin          = each.value.contact_admin
  contact_billing        = each.value.contact_billing
  contact_registrant     = each.value.contact_registrant
  contact_tech           = each.value.contact_tech
  consent_agreed_by      = each.value.consent_agreed_by
  consent_agreed_at      = each.value.consent_agreed_at
  consent_agreement_keys = try(each.value.consent_agreement_keys, [])
  privacy                = try(each.value.privacy, true)
  auto_renew             = try(each.value.auto_renew, true)
  dns_type               = try(each.value.dns_type, "AzureDns")
  dns_zone_id            = try(each.value.dns_zone_id, null)
  tags                   = try(each.value.tags, null)
  check_existance        = var.check_existance
}
