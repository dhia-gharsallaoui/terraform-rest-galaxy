# ── Public IP Addresses ───────────────────────────────────────────────────────

variable "azure_public_ip_addresses" {
  type = map(object({
    subscription_id         = string
    resource_group_name     = string
    public_ip_address_name  = optional(string, null)
    location                = optional(string, null)
    sku_name                = string
    sku_tier                = optional(string, null)
    allocation_method       = string
    ip_version              = optional(string, null)
    idle_timeout_in_minutes = optional(number, null)
    zones                   = optional(list(string), null)
    tags                    = optional(map(string), null)
  }))
  description = "Map of public IP addresses to create."
  default     = {}
}

locals {
  azure_public_ip_addresses = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_public_ip_addresses, {}), var.azure_public_ip_addresses)
  )
  _pip_ctx = provider::rest::merge_with_outputs(local.azure_public_ip_addresses, module.azure_public_ip_addresses)
}

module "azure_public_ip_addresses" {
  source   = "./modules/azure/public_ip_address"
  for_each = local.azure_public_ip_addresses

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations]

  subscription_id         = try(each.value.subscription_id, var.subscription_id)
  resource_group_name     = each.value.resource_group_name
  public_ip_address_name  = try(each.value.public_ip_address_name, null) != null ? each.value.public_ip_address_name : each.key
  location                = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  sku_name                = each.value.sku_name
  sku_tier                = try(each.value.sku_tier, null)
  allocation_method       = each.value.allocation_method
  ip_version              = try(each.value.ip_version, null)
  idle_timeout_in_minutes = try(each.value.idle_timeout_in_minutes, null)
  zones                   = try(each.value.zones, null)
  tags                    = try(each.value.tags, null)
  check_existance         = var.check_existance
}
