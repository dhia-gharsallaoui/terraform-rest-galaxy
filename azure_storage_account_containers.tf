# ── Storage Account Containers ────────────────────────────────────────────────

variable "azure_storage_account_containers" {
  type = map(object({
    subscription_id     = optional(string, null)
    resource_group_name = string
    account_name        = string
    container_name      = string
    public_access       = optional(string, "None")
    _tenant             = optional(string, null)
  }))
  description = <<-EOT
    Map of blob containers to create inside storage accounts.

    Example:
      azure_storage_account_containers = {
        tfstate = {
          resource_group_name = "rg-terraform-state"
          account_name        = "stdplstate001"
          container_name      = "tfstate"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_storage_account_containers = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_containers, {}), var.azure_storage_account_containers)
  )
}

module "azure_storage_account_containers" {
  source   = "./modules/azure/storage_account_container"
  for_each = local.azure_storage_account_containers

  depends_on = [module.azure_storage_accounts]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  container_name      = each.value.container_name
  public_access       = try(each.value.public_access, "None")

  auth_ref = try(each.value._tenant, null)
}
