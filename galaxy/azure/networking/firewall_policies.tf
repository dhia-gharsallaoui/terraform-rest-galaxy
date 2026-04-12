# ── Firewall Policies ─────────────────────────────────────────────────────────

variable "azure_firewall_policies" {
  type = map(object({
    subscription_id      = string
    resource_group_name  = string
    firewall_policy_name = string
    location             = optional(string, null)
    sku_tier             = optional(string, "Standard")
    base_policy_id       = optional(string, null)
    threat_intel_mode    = optional(string, null)
    dns_servers          = optional(list(string), null)
    dns_proxy_enabled    = optional(bool, null)
    explicit_proxy = optional(object({
      enable_explicit_proxy = bool
      http_port             = optional(number)
      https_port            = optional(number)
      enable_pac_file       = optional(bool)
      pac_file_port         = optional(number)
      pac_file_sas_url      = optional(string)
    }), null)
    tags = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Firewall Policies to create. Each map key acts as the for_each identifier.

    Example:
      azure_firewall_policies = {
        hub = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-networking"
          location            = "westeurope"
          sku_tier            = "Standard"
          threat_intel_mode   = "Alert"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_firewall_policies = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_firewall_policies, {}), var.azure_firewall_policies)
  )
  _fwp_ctx = provider::rest::merge_with_outputs(local.azure_firewall_policies, module.azure_firewall_policies)
}

module "azure_firewall_policies" {
  source   = "./modules/azure/firewall_policy"
  for_each = local.azure_firewall_policies

  depends_on = [module.azure_resource_groups, module.azure_resource_provider_registrations]

  subscription_id      = try(each.value.subscription_id, var.subscription_id)
  resource_group_name  = each.value.resource_group_name
  firewall_policy_name = each.value.firewall_policy_name
  location             = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  sku_tier             = try(each.value.sku_tier, "Standard")
  base_policy_id       = try(each.value.base_policy_id, null)
  threat_intel_mode    = try(each.value.threat_intel_mode, null)
  dns_servers          = try(each.value.dns_servers, null)
  dns_proxy_enabled    = try(each.value.dns_proxy_enabled, null)
  explicit_proxy       = try(each.value.explicit_proxy, null)
  tags                 = try(each.value.tags, null)
  check_existance      = var.check_existance
}
