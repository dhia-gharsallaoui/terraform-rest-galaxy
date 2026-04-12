# ── Azure Firewalls ───────────────────────────────────────────────────────────

variable "azure_firewalls" {
  type = map(object({
    subscription_id     = string
    resource_group_name = string
    firewall_name       = string
    location            = optional(string, null)
    sku_name            = string
    sku_tier            = string
    virtual_hub_id      = optional(string, null)
    firewall_policy_id  = optional(string, null)
    threat_intel_mode   = optional(string, null)
    public_ip_count     = optional(number, null)
    zones               = optional(list(string), null)
    ip_configurations = optional(list(object({
      name                 = string
      subnet_id            = optional(string)
      public_ip_address_id = optional(string)
    })), null)
    additional_properties        = optional(map(string), {})
    application_rule_collections = optional(list(any), [])
    nat_rule_collections         = optional(list(any), [])
    network_rule_collections     = optional(list(any), [])
    tags                         = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Azure Firewalls to create. Each map key acts as the for_each identifier.

    Example:
      azure_firewalls = {
        hub = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-networking"
          location            = "westeurope"
          sku_name            = "AZFW_Hub"
          sku_tier            = "Standard"
          virtual_hub_id      = "/subscriptions/.../providers/Microsoft.Network/virtualHubs/myHub"
          firewall_policy_id  = "/subscriptions/.../providers/Microsoft.Network/firewallPolicies/myPolicy"
          public_ip_count     = 1
        }
      }
  EOT
  default     = {}
}

locals {
  azure_firewalls = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_firewalls, {}), var.azure_firewalls)
  )
  _afw_ctx = provider::rest::merge_with_outputs(local.azure_firewalls, module.azure_firewalls)
}

module "azure_firewalls" {
  source   = "./modules/azure/azure_firewall"
  for_each = local.azure_firewalls

  depends_on = [module.azure_virtual_hubs, module.azure_firewall_policies]

  subscription_id              = try(each.value.subscription_id, var.subscription_id)
  resource_group_name          = each.value.resource_group_name
  firewall_name                = each.value.firewall_name
  location                     = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  sku_name                     = each.value.sku_name
  sku_tier                     = each.value.sku_tier
  virtual_hub_id               = try(each.value.virtual_hub_id, null)
  firewall_policy_id           = try(each.value.firewall_policy_id, null)
  threat_intel_mode            = try(each.value.threat_intel_mode, null)
  public_ip_count              = try(each.value.public_ip_count, null)
  zones                        = try(each.value.zones, null)
  ip_configurations            = try(each.value.ip_configurations, null)
  additional_properties        = try(each.value.additional_properties, {})
  application_rule_collections = try(each.value.application_rule_collections, [])
  nat_rule_collections         = try(each.value.nat_rule_collections, [])
  network_rule_collections     = try(each.value.network_rule_collections, [])
  tags                         = try(each.value.tags, null)
  check_existance              = var.check_existance
}
