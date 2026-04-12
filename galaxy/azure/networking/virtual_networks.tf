# ── Virtual Networks ──────────────────────────────────────────────────────────

variable "azure_virtual_networks" {
  type = map(object({
    subscription_id         = string
    resource_group_name     = string
    virtual_network_name    = optional(string, null)
    location                = optional(string, null)
    address_space           = list(string)
    dns_servers             = optional(list(string), null)
    enable_ddos_protection  = optional(bool, null)
    ddos_protection_plan_id = optional(string, null)
    subnets = optional(list(object({
      name                              = string
      address_prefix                    = string
      route_table_id                    = optional(string, null)
      network_security_group_id         = optional(string, null)
      delegations                       = optional(list(string), null)
      private_endpoint_network_policies = optional(string, null)
    })), null)
    tags = optional(map(string), null)
  }))
  description = "Map of virtual networks to create."
  default     = {}
}

locals {
  azure_virtual_networks = provider::rest::resolve_map(
    local._ctx_l0e,
    merge(try(local._yaml_raw.azure_virtual_networks, {}), var.azure_virtual_networks)
  )
  _vnet_ctx = provider::rest::merge_with_outputs(local.azure_virtual_networks, module.azure_virtual_networks)
}

module "azure_virtual_networks" {
  source   = "./modules/azure/virtual_network"
  for_each = local.azure_virtual_networks

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations, module.azure_ipam_static_cidrs]

  subscription_id         = try(each.value.subscription_id, var.subscription_id)
  resource_group_name     = each.value.resource_group_name
  virtual_network_name    = try(each.value.virtual_network_name, each.key)
  location                = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  address_space           = each.value.address_space
  dns_servers             = try(each.value.dns_servers, null)
  enable_ddos_protection  = try(each.value.enable_ddos_protection, null)
  ddos_protection_plan_id = try(each.value.ddos_protection_plan_id, null)
  subnets                 = try(each.value.subnets, null)
  tags                    = try(each.value.tags, null)
  check_existance         = var.check_existance
}
