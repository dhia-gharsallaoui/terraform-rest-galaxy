# ── Virtual Network Gateways ──────────────────────────────────────────────────

variable "azure_virtual_network_gateways" {
  type = map(object({
    subscription_id           = string
    resource_group_name       = string
    gateway_name              = optional(string, null)
    location                  = optional(string, null)
    gateway_type              = string
    sku_name                  = string
    sku_tier                  = string
    vpn_type                  = optional(string, null)
    vpn_gateway_generation    = optional(string, null)
    enable_bgp                = optional(bool, null)
    active_active             = optional(bool, null)
    enable_private_ip_address = optional(bool, null)
    admin_state               = optional(string, null)
    ip_configurations = optional(list(object({
      name                 = string
      subnet_id            = optional(string)
      public_ip_address_id = optional(string)
    })), null)
    vpn_client_configuration = optional(object({
      address_prefixes         = list(string)
      vpn_client_protocols     = optional(list(string))
      vpn_authentication_types = optional(list(string))
      aad_tenant               = optional(string)
      aad_audience             = optional(string)
      aad_issuer               = optional(string)
      radius_server_address    = optional(string)
      radius_server_secret     = optional(string)
    }), null)
    tags = optional(map(string), null)
  }))
  description = "Map of virtual network gateways to create."
  default     = {}
}

locals {
  azure_virtual_network_gateways = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_virtual_network_gateways, {}), var.azure_virtual_network_gateways)
  )
  _vngw_ctx = provider::rest::merge_with_outputs(local.azure_virtual_network_gateways, module.azure_virtual_network_gateways)

  # AZ-aware VPN/ER SKUs — Public IPs with zones require one of these
  _az_gateway_skus = toset([
    "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ",
    "ErGw1AZ", "ErGw2AZ", "ErGw3AZ",
  ])

  # Build a map of PIP resource IDs → their zone config from resolved PIP inputs
  _pip_zones_by_id = {
    for k, v in local.azure_public_ip_addresses :
    "/subscriptions/${try(v.subscription_id, var.subscription_id)}/resourceGroups/${v.resource_group_name}/providers/Microsoft.Network/publicIPAddresses/${try(v.public_ip_address_name, null) != null ? v.public_ip_address_name : k}"
    => try(v.zones, null)
  }

  # Detect gateways with non-AZ SKU referencing zoned PIPs
  _vngw_zone_conflicts = {
    for gw_key, gw in local.azure_virtual_network_gateways :
    gw_key => [
      for ipc in try(gw.ip_configurations, []) :
      ipc.public_ip_address_id
      if ipc.public_ip_address_id != null
      && !contains(local._az_gateway_skus, gw.sku_name)
      && length(try(local._pip_zones_by_id[ipc.public_ip_address_id], null) != null ? local._pip_zones_by_id[ipc.public_ip_address_id] : []) > 0
    ]
    if length([
      for ipc in try(gw.ip_configurations, []) :
      ipc.public_ip_address_id
      if ipc.public_ip_address_id != null
      && !contains(local._az_gateway_skus, gw.sku_name)
      && length(try(local._pip_zones_by_id[ipc.public_ip_address_id], null) != null ? local._pip_zones_by_id[ipc.public_ip_address_id] : []) > 0
    ]) > 0
  }
}

resource "terraform_data" "vngw_zone_validation" {
  for_each = local._vngw_zone_conflicts

  lifecycle {
    precondition {
      condition     = length(each.value) == 0
      error_message = <<-EOT
        VALIDATION: Virtual network gateway '${each.key}' uses a non-AZ SKU but
        references Public IP(s) with availability zones configured:
          ${join(", ", each.value)}

        Non-AZ SKUs (e.g. VpnGw1, ErGw1) cannot use zoned Public IPs.
        Fix: use an AZ SKU (e.g. VpnGw1AZ) or remove zones from the Public IP.
      EOT
    }
  }
}

module "azure_virtual_network_gateways" {
  source   = "./modules/azure/virtual_network_gateway"
  for_each = local.azure_virtual_network_gateways

  depends_on = [module.azure_virtual_networks, module.azure_public_ip_addresses]

  subscription_id           = try(each.value.subscription_id, var.subscription_id)
  resource_group_name       = each.value.resource_group_name
  gateway_name              = try(each.value.gateway_name, null) != null ? each.value.gateway_name : each.key
  location                  = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  gateway_type              = each.value.gateway_type
  sku_name                  = each.value.sku_name
  sku_tier                  = each.value.sku_tier
  vpn_type                  = try(each.value.vpn_type, null)
  vpn_gateway_generation    = try(each.value.vpn_gateway_generation, null)
  enable_bgp                = try(each.value.enable_bgp, null)
  active_active             = try(each.value.active_active, null)
  enable_private_ip_address = try(each.value.enable_private_ip_address, null)
  admin_state               = try(each.value.admin_state, null)
  ip_configurations         = try(each.value.ip_configurations, null)
  vpn_client_configuration  = try(each.value.vpn_client_configuration, null)
  tags                      = try(each.value.tags, null)
  check_existance           = var.check_existance
}
