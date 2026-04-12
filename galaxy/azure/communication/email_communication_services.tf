# ── Email Communication Services ──────────────────────────────────────────────

variable "azure_email_communication_services" {
  type = map(object({
    subscription_id     = optional(string)
    resource_group_name = string
    email_service_name  = string
    location            = optional(string, "global")
    data_location       = optional(string, "Europe")
    tags                = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Email Communication Services to create.

    Example:
      azure_email_communication_services = {
        email = {
          resource_group_name = "rg-acs"
          email_service_name  = "acs-email-svc"
          location            = "global"
          data_location       = "Europe"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_email_communication_services = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_email_communication_services, {}), var.azure_email_communication_services)
  )
  _ecs_ctx = provider::rest::merge_with_outputs(local.azure_email_communication_services, module.azure_email_communication_services)
}

module "azure_email_communication_services" {
  source   = "./modules/azure/email_communication_service"
  for_each = local.azure_email_communication_services

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  email_service_name  = each.value.email_service_name
  location            = try(each.value.location, "global")
  data_location       = try(each.value.data_location, "Europe")
  tags                = try(each.value.tags, null)
  check_existance     = var.check_existance
}
