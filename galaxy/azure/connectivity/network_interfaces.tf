# ── Network Interfaces ────────────────────────────────────────────────────────

variable "azure_network_interfaces" {
  type = map(object({
    subscription_id        = string
    resource_group_name    = string
    network_interface_name = optional(string, null)
    location               = optional(string, null)
    ip_configurations = list(object({
      name                         = string
      subnet_id                    = optional(string)
      private_ip_address           = optional(string)
      private_ip_allocation_method = optional(string)
      private_ip_address_version   = optional(string)
      primary                      = optional(bool)
    }))
    enable_accelerated_networking = optional(bool, null)
    enable_ip_forwarding          = optional(bool, null)
    dns_servers                   = optional(list(string), null)
    network_security_group_id     = optional(string, null)
    tags                          = optional(map(string), null)
  }))
  description = "Map of network interfaces to create."
  default     = {}
}

locals {
  azure_network_interfaces = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_network_interfaces, {}), var.azure_network_interfaces)
  )
  _nic_ctx = provider::rest::merge_with_outputs(local.azure_network_interfaces, module.azure_network_interfaces)
}

module "azure_network_interfaces" {
  source   = "./modules/azure/network_interface"
  for_each = local.azure_network_interfaces

  depends_on = [module.azure_virtual_networks]

  subscription_id               = try(each.value.subscription_id, var.subscription_id)
  resource_group_name           = each.value.resource_group_name
  network_interface_name        = try(each.value.network_interface_name, null) != null ? each.value.network_interface_name : each.key
  location                      = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  ip_configurations             = each.value.ip_configurations
  enable_accelerated_networking = try(each.value.enable_accelerated_networking, null)
  enable_ip_forwarding          = try(each.value.enable_ip_forwarding, null)
  dns_servers                   = try(each.value.dns_servers, null)
  network_security_group_id     = try(each.value.network_security_group_id, null)
  tags                          = try(each.value.tags, null)
  check_existance               = var.check_existance
}
