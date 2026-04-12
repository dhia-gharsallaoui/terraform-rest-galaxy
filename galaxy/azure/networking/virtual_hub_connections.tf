# ── Virtual Hub Connections ────────────────────────────────────────────────────

variable "azure_virtual_hub_connections" {
  type = map(object({
    subscription_id                            = string
    resource_group_name                        = string
    virtual_hub_name                           = string
    connection_name                            = optional(string, null)
    remote_virtual_network_id                  = string
    enable_internet_security                   = optional(bool, null)
    allow_hub_to_remote_vnet_transit           = optional(bool, null)
    allow_remote_vnet_to_use_hub_vnet_gateways = optional(bool, null)
  }))
  description = <<-EOT
    Map of Virtual Hub VNet Connections to create. Each map key acts as the for_each identifier.

    Example:
      azure_virtual_hub_connections = {
        hub3-vnet1 = {
          subscription_id           = "00000000-0000-0000-0000-000000000000"
          resource_group_name       = "rg-networking"
          virtual_hub_name          = "vhub-israelcentral-01"
          remote_virtual_network_id = "/subscriptions/.../providers/Microsoft.Network/virtualNetworks/myVnet"
          enable_internet_security  = true
        }
      }
  EOT
  default     = {}
}

locals {
  azure_virtual_hub_connections = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_virtual_hub_connections, {}), var.azure_virtual_hub_connections)
  )
  _vhc_ctx = provider::rest::merge_with_outputs(local.azure_virtual_hub_connections, module.azure_virtual_hub_connections)
}

module "azure_virtual_hub_connections" {
  source   = "./modules/azure/virtual_hub_connection"
  for_each = local.azure_virtual_hub_connections

  depends_on = [module.azure_virtual_hubs, module.azure_virtual_networks]

  subscription_id                            = try(each.value.subscription_id, var.subscription_id)
  resource_group_name                        = each.value.resource_group_name
  virtual_hub_name                           = each.value.virtual_hub_name
  connection_name                            = try(each.value.connection_name, null) != null ? each.value.connection_name : each.key
  remote_virtual_network_id                  = each.value.remote_virtual_network_id
  enable_internet_security                   = try(each.value.enable_internet_security, null)
  allow_hub_to_remote_vnet_transit           = try(each.value.allow_hub_to_remote_vnet_transit, null)
  allow_remote_vnet_to_use_hub_vnet_gateways = try(each.value.allow_remote_vnet_to_use_hub_vnet_gateways, null)
  check_existance                            = var.check_existance
}
