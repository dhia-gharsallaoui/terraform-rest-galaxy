# ── GitHub.Network Network Settings ───────────────────────────────────────────

variable "azure_github_network_settings" {
  type = map(object({
    subscription_id       = optional(string)
    resource_group_name   = string
    network_settings_name = optional(string, null)
    location              = optional(string, null)
    subnet_id             = string
    business_id           = string
    tags                  = optional(map(string), null)
  }))
  description = <<-EOT
    Map of GitHub.Network networkSettings resources to create. Links an Azure
    subnet to a GitHub organization/enterprise for VNet-injected hosted runners.

    Requires:
      - The GitHub.Network resource provider registered on the subscription
      - A subnet with delegation to GitHub.Network/networkSettings
      - The GitHub business (org/enterprise) database ID

    Example:
      azure_github_network_settings = {
        runners = {
          resource_group_name   = "rg-github-runners"
          subnet_id             = "/subscriptions/.../subnets/runner-subnet"
          business_id           = "123456789"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_github_network_settings = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_github_network_settings, {}), var.azure_github_network_settings)
  )
  _ghns_ctx = provider::rest::merge_with_outputs(local.azure_github_network_settings, module.azure_github_network_settings)
}

module "azure_github_network_settings" {
  source   = "./modules/azure/github_network_settings"
  for_each = local.azure_github_network_settings

  depends_on = [module.azure_virtual_networks, module.azure_resource_provider_registrations]

  subscription_id       = try(each.value.subscription_id, var.subscription_id)
  resource_group_name   = each.value.resource_group_name
  network_settings_name = try(each.value.network_settings_name, null) != null ? each.value.network_settings_name : each.key
  location              = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  subnet_id             = each.value.subnet_id
  business_id           = each.value.business_id
  tags                  = try(each.value.tags, null)
  check_existance       = var.check_existance
}
