# ── VPN Gateways (vWAN S2S) ───────────────────────────────────────────────────

variable "azure_vpn_gateways" {
  type = map(object({
    subscription_id                      = string
    resource_group_name                  = string
    gateway_name                         = optional(string, null)
    location                             = optional(string, null)
    virtual_hub_id                       = string
    vpn_gateway_scale_unit               = optional(number, null)
    enable_bgp_route_translation_for_nat = optional(bool, null)
    is_routing_preference_internet       = optional(bool, null)
    tags                                 = optional(map(string), null)
  }))
  description = <<-EOT
    Map of VPN Gateways (vWAN S2S) to create. Each map key acts as the for_each identifier.

    Example:
      azure_vpn_gateways = {
        hub1 = {
          subscription_id        = "00000000-0000-0000-0000-000000000000"
          resource_group_name    = "rg-networking"
          location               = "westus"
          virtual_hub_id         = "/subscriptions/.../providers/Microsoft.Network/virtualHubs/myHub"
          vpn_gateway_scale_unit = 40
        }
      }
  EOT
  default     = {}
}

locals {
  azure_vpn_gateways = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_vpn_gateways, {}), var.azure_vpn_gateways)
  )
  _vpngw_ctx = provider::rest::merge_with_outputs(local.azure_vpn_gateways, module.azure_vpn_gateways)
}

module "azure_vpn_gateways" {
  source   = "./modules/azure/vpn_gateway"
  for_each = local.azure_vpn_gateways

  depends_on = [module.azure_virtual_hubs]

  subscription_id                      = try(each.value.subscription_id, var.subscription_id)
  resource_group_name                  = each.value.resource_group_name
  gateway_name                         = try(each.value.gateway_name, null) != null ? each.value.gateway_name : each.key
  location                             = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  virtual_hub_id                       = each.value.virtual_hub_id
  vpn_gateway_scale_unit               = try(each.value.vpn_gateway_scale_unit, null)
  enable_bgp_route_translation_for_nat = try(each.value.enable_bgp_route_translation_for_nat, null)
  is_routing_preference_internet       = try(each.value.is_routing_preference_internet, null)
  tags                                 = try(each.value.tags, null)
  check_existance                      = var.check_existance
}
