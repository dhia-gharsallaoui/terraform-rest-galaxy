# ── Email Communication Service Domains ───────────────────────────────────────

variable "azure_email_communication_service_domains" {
  type = map(object({
    subscription_id          = optional(string)
    resource_group_name      = string
    email_service_name       = string
    domain_name              = string
    location                 = optional(string, "global")
    domain_management        = optional(string, "AzureManaged")
    user_engagement_tracking = optional(string, null)
    tags                     = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Email Communication Service domains to create.

    Example:
      azure_email_communication_service_domains = {
        azure_managed = {
          resource_group_name = "rg-acs"
          email_service_name  = "ref:azure_email_communication_services.email.name"
          domain_name         = "AzureManagedDomain"
          location            = "global"
          domain_management   = "AzureManaged"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_email_communication_service_domains = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_email_communication_service_domains, {}), var.azure_email_communication_service_domains)
  )
  _ecsd_ctx = provider::rest::merge_with_outputs(local.azure_email_communication_service_domains, module.azure_email_communication_service_domains)
}

module "azure_email_communication_service_domains" {
  source   = "./modules/azure/email_communication_service_domain"
  for_each = local.azure_email_communication_service_domains

  depends_on = [module.azure_email_communication_services]

  subscription_id          = try(each.value.subscription_id, var.subscription_id)
  resource_group_name      = each.value.resource_group_name
  email_service_name       = each.value.email_service_name
  domain_name              = each.value.domain_name
  location                 = try(each.value.location, "global")
  domain_management        = try(each.value.domain_management, "AzureManaged")
  user_engagement_tracking = try(each.value.user_engagement_tracking, null)
  tags                     = try(each.value.tags, null)
  check_existance          = var.check_existance
}
