# ── Storage Account Tables ────────────────────────────────────────────────────

variable "azure_storage_account_tables" {
  type = map(object({
    subscription_id     = optional(string, null)
    resource_group_name = string
    account_name        = string
    table_name          = string
    signed_identifiers = optional(list(object({
      id = string
      access_policy = optional(object({
        start_time  = optional(string, null)
        expiry_time = optional(string, null)
        permission  = optional(string, null)
      }), null)
    })), null)
  }))
  description = <<-EOT
    Map of tables to create inside storage accounts.

    Example:
      azure_storage_account_tables = {
        products = {
          resource_group_name = "rg-myapp"
          account_name        = "stmyapp001"
          table_name          = "Products"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_storage_account_tables = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_tables, {}), var.azure_storage_account_tables)
  )
}

module "azure_storage_account_tables" {
  source   = "./modules/azure/storage_account_table"
  for_each = local.azure_storage_account_tables

  depends_on = [module.azure_storage_accounts]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  table_name          = each.value.table_name
  signed_identifiers  = try(each.value.signed_identifiers, null)
  check_existance     = var.check_existance
}
