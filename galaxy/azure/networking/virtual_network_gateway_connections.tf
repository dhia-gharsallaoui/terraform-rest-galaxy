# ── Virtual Network Gateway Connections ───────────────────────────────────────

variable "azure_virtual_network_gateway_connections" {
  type = map(object({
    subscription_id               = string
    resource_group_name           = string
    connection_name               = optional(string, null)
    location                      = optional(string, null)
    connection_type               = string
    virtual_network_gateway1_id   = string
    virtual_network_gateway2_id   = optional(string, null)
    peer_id                       = optional(string, null)
    routing_weight                = optional(number, null)
    enable_bgp                    = optional(bool, null)
    express_route_gateway_bypass  = optional(bool, null)
    enable_private_link_fast_path = optional(bool, null)
    tags                          = optional(map(string), null)
  }))
  description = "Map of virtual network gateway connections to create."
  default     = {}
}

locals {
  azure_virtual_network_gateway_connections = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_virtual_network_gateway_connections, {}), var.azure_virtual_network_gateway_connections)
  )
  _conn_ctx = provider::rest::merge_with_outputs(local.azure_virtual_network_gateway_connections, module.azure_virtual_network_gateway_connections)
}

module "azure_virtual_network_gateway_connections" {
  source   = "./modules/azure/virtual_network_gateway_connection"
  for_each = local.azure_virtual_network_gateway_connections

  depends_on = [module.azure_virtual_network_gateways, module.azure_express_route_circuits]

  subscription_id               = try(each.value.subscription_id, var.subscription_id)
  resource_group_name           = each.value.resource_group_name
  connection_name               = try(each.value.connection_name, null) != null ? each.value.connection_name : each.key
  location                      = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  connection_type               = each.value.connection_type
  virtual_network_gateway1_id   = each.value.virtual_network_gateway1_id
  virtual_network_gateway2_id   = try(each.value.virtual_network_gateway2_id, null)
  peer_id                       = try(each.value.peer_id, null)
  routing_weight                = try(each.value.routing_weight, null)
  enable_bgp                    = try(each.value.enable_bgp, null)
  express_route_gateway_bypass  = try(each.value.express_route_gateway_bypass, null)
  enable_private_link_fast_path = try(each.value.enable_private_link_fast_path, null)
  tags                          = try(each.value.tags, null)
  check_existance               = var.check_existance
}
