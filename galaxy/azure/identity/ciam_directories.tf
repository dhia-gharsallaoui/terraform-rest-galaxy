# ── CIAM Directories (Azure AD for Customers) ────────────────────────────────

variable "azure_ciam_directories" {
  type = map(object({
    subscription_id     = string
    resource_group_name = string
    resource_name       = string
    location            = string
    display_name        = string
    country_code        = string
    sku_name            = optional(string, "Standard")
    tags                = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Azure AD for customers (CIAM) directories to create. Each map key
    acts as the for_each identifier and must be unique within this configuration.

    Example:
      azure_ciam_directories = {
        customer_portal = {
          subscription_id     = "00000000-0000-0000-0000-000000000000"
          resource_group_name = "rg-identity-prod"
          resource_name       = "myappciamprod"
          location            = "Europe"
          display_name        = "My App Customer Portal"
          country_code        = "FR"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_ciam_directories = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_ciam_directories, {}), var.azure_ciam_directories)
  )
  _ciam_ctx = provider::rest::merge_with_outputs(local.azure_ciam_directories, module.azure_ciam_directories)
}

module "azure_ciam_directories" {
  source   = "./modules/azure/ciam_directory"
  for_each = local.azure_ciam_directories

  depends_on = [module.azure_resource_groups]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  resource_name       = each.value.resource_name
  location            = each.value.location
  display_name        = each.value.display_name
  country_code        = each.value.country_code
  sku_name            = try(each.value.sku_name, "Standard")
  tags                = try(each.value.tags, null)
  check_existance     = var.check_existance
}
