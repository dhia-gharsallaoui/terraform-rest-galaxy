# ── Express Route Circuits ────────────────────────────────────────────────────

variable "azure_express_route_circuits" {
  type = map(object({
    subscription_id          = string
    resource_group_name      = string
    circuit_name             = optional(string, null)
    location                 = optional(string, null)
    sku_tier                 = string
    sku_family               = string
    bandwidth_in_gbps        = optional(number, null)
    bandwidth_in_mbps        = optional(number, null)
    express_route_port_id    = optional(string, null)
    service_provider_name    = optional(string, null)
    peering_location         = optional(string, null)
    allow_classic_operations = optional(bool, null)
    global_reach_enabled     = optional(bool, null)
    tags                     = optional(map(string), null)
  }))
  description = "Map of ExpressRoute circuits to create."
  default     = {}
}

locals {
  azure_express_route_circuits = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_express_route_circuits, {}), var.azure_express_route_circuits)
  )
  _erc_ctx = provider::rest::merge_with_outputs(local.azure_express_route_circuits, module.azure_express_route_circuits)
}

module "azure_express_route_circuits" {
  source   = "./modules/azure/express_route_circuit"
  for_each = local.azure_express_route_circuits

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations]

  subscription_id          = try(each.value.subscription_id, var.subscription_id)
  resource_group_name      = each.value.resource_group_name
  circuit_name             = try(each.value.circuit_name, null) != null ? each.value.circuit_name : each.key
  location                 = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  sku_tier                 = each.value.sku_tier
  sku_family               = each.value.sku_family
  bandwidth_in_gbps        = try(each.value.bandwidth_in_gbps, null)
  bandwidth_in_mbps        = try(each.value.bandwidth_in_mbps, null)
  express_route_port_id    = try(each.value.express_route_port_id, null)
  service_provider_name    = try(each.value.service_provider_name, null)
  peering_location         = try(each.value.peering_location, null)
  allow_classic_operations = try(each.value.allow_classic_operations, null)
  global_reach_enabled     = try(each.value.global_reach_enabled, null)
  tags                     = try(each.value.tags, null)
  check_existance          = var.check_existance
}
