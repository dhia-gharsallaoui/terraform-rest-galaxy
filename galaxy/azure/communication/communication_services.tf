# ── Communication Services ────────────────────────────────────────────────────

variable "azure_communication_services" {
  type = map(object({
    subscription_id            = optional(string)
    resource_group_name        = string
    communication_service_name = string
    location                   = optional(string, "global")
    data_location              = optional(string, "Europe")
    linked_domains             = optional(list(string), null)
    public_network_access      = optional(string, null)
    disable_local_auth         = optional(bool, null)
    tags                       = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Communication Services to create.

    Example:
      azure_communication_services = {
        main = {
          resource_group_name        = "rg-acs"
          communication_service_name = "acs-main"
          location                   = "global"
          data_location              = "Europe"
          linked_domains             = ["ref:azure_email_communication_service_domains.azure_managed.id"]
        }
      }
  EOT
  default     = {}
}

locals {
  azure_communication_services = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_communication_services, {}), var.azure_communication_services)
  )
  _acs_ctx = provider::rest::merge_with_outputs(local.azure_communication_services, module.azure_communication_services)
}

module "azure_communication_services" {
  source   = "./modules/azure/communication_service"
  for_each = local.azure_communication_services

  depends_on = [module.azure_email_communication_service_domains]

  subscription_id            = try(each.value.subscription_id, var.subscription_id)
  resource_group_name        = each.value.resource_group_name
  communication_service_name = each.value.communication_service_name
  location                   = try(each.value.location, "global")
  data_location              = try(each.value.data_location, "Europe")
  linked_domains             = try(each.value.linked_domains, null)
  public_network_access      = try(each.value.public_network_access, null)
  disable_local_auth         = try(each.value.disable_local_auth, null)
  tags                       = try(each.value.tags, null)
  check_existance            = var.check_existance
}
