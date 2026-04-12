# ── Virtual Hubs ──────────────────────────────────────────────────────────────

variable "azure_virtual_hubs" {
  type = map(object({
    subscription_id                        = string
    resource_group_name                    = string
    virtual_hub_name                       = string
    location                               = optional(string, null)
    virtual_wan_id                         = string
    address_prefix                         = string
    sku                                    = optional(string, "Standard")
    allow_branch_to_branch_traffic         = optional(bool, null)
    hub_routing_preference                 = optional(string, null)
    virtual_router_auto_scale_min_capacity = optional(number, null)
    tags                                   = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Virtual Hubs to create. Each map key acts as the for_each identifier.

    Example:
      azure_virtual_hubs = {
        hub = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-networking"
          location            = "westeurope"
          virtual_wan_id      = "/subscriptions/.../providers/Microsoft.Network/virtualWans/myWan"
          address_prefix      = "10.0.0.0/24"
          sku                 = "Standard"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_virtual_hubs = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_virtual_hubs, {}), var.azure_virtual_hubs)
  )
  _vhub_ctx = provider::rest::merge_with_outputs(local.azure_virtual_hubs, module.azure_virtual_hubs)
}

module "azure_virtual_hubs" {
  source   = "./modules/azure/virtual_hub"
  for_each = local.azure_virtual_hubs

  depends_on = [module.azure_virtual_wans]

  subscription_id                        = try(each.value.subscription_id, var.subscription_id)
  resource_group_name                    = each.value.resource_group_name
  virtual_hub_name                       = each.value.virtual_hub_name
  location                               = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  virtual_wan_id                         = each.value.virtual_wan_id
  address_prefix                         = each.value.address_prefix
  sku                                    = try(each.value.sku, "Standard")
  allow_branch_to_branch_traffic         = try(each.value.allow_branch_to_branch_traffic, null)
  hub_routing_preference                 = try(each.value.hub_routing_preference, null)
  virtual_router_auto_scale_min_capacity = try(each.value.virtual_router_auto_scale_min_capacity, null)
  tags                                   = try(each.value.tags, null)
  check_existance                        = var.check_existance
}
