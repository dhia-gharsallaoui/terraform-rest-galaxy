# ── DNS Zones ─────────────────────────────────────────────────────────────────

variable "azure_dns_zones" {
  type = map(object({
    subscription_id     = optional(string)
    resource_group_name = string
    zone_name           = string
    location            = optional(string, "global")
    zone_type           = optional(string, "Public")
    tags                = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Azure DNS zones to create.

    Example:
      azure_dns_zones = {
        contoso = {
          resource_group_name = "rg-dns"
          zone_name           = "contoso.com"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_dns_zones = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_dns_zones, {}), var.azure_dns_zones)
  )
  _dz_ctx = provider::rest::merge_with_outputs(local.azure_dns_zones, module.azure_dns_zones)
}

module "azure_dns_zones" {
  source   = "./modules/azure/dns_zone"
  for_each = local.azure_dns_zones

  depends_on = [module.azure_app_service_domains]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  zone_name           = each.value.zone_name
  location            = try(each.value.location, "global")
  zone_type           = try(each.value.zone_type, "Public")
  tags                = try(each.value.tags, null)
  check_existance     = var.check_existance
}
