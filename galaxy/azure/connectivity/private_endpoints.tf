# ── Private Endpoints ─────────────────────────────────────────────────────────

variable "azure_private_endpoints" {
  type = map(object({
    subscription_id               = string
    resource_group_name           = string
    private_endpoint_name         = optional(string, null)
    location                      = optional(string, null)
    subnet_id                     = string
    custom_network_interface_name = optional(string, null)
    private_link_service_connections = optional(list(object({
      name                    = string
      private_link_service_id = string
      group_ids               = optional(list(string))
      request_message         = optional(string)
    })), null)
    manual_private_link_service_connections = optional(list(object({
      name                    = string
      private_link_service_id = string
      group_ids               = optional(list(string))
      request_message         = optional(string)
    })), null)
    ip_configurations = optional(list(object({
      name               = string
      group_id           = optional(string)
      member_name        = optional(string)
      private_ip_address = string
    })), null)
    private_dns_zone_group = optional(object({
      name                 = optional(string, "default")
      private_dns_zone_ids = list(string)
    }), null)
    tags = optional(map(string), null)
  }))
  description = "Map of private endpoints to create."
  default     = {}
}

locals {
  azure_private_endpoints = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_private_endpoints, {}), var.azure_private_endpoints)
  )
  _pe_ctx = provider::rest::merge_with_outputs(local.azure_private_endpoints, module.azure_private_endpoints)
}

module "azure_private_endpoints" {
  source   = "./modules/azure/private_endpoint"
  for_each = local.azure_private_endpoints

  depends_on = [module.azure_virtual_networks]

  subscription_id                         = try(each.value.subscription_id, var.subscription_id)
  resource_group_name                     = each.value.resource_group_name
  private_endpoint_name                   = try(each.value.private_endpoint_name, null) != null ? each.value.private_endpoint_name : each.key
  location                                = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  subnet_id                               = each.value.subnet_id
  custom_network_interface_name           = try(each.value.custom_network_interface_name, null)
  private_link_service_connections        = try(each.value.private_link_service_connections, null)
  manual_private_link_service_connections = try(each.value.manual_private_link_service_connections, null)
  ip_configurations                       = try(each.value.ip_configurations, null)
  private_dns_zone_group                  = try(each.value.private_dns_zone_group, null)
  tags                                    = try(each.value.tags, null)
  check_existance                         = var.check_existance
}
