# ── Storage Account Inventory Policies ───────────────────────────────────────

variable "azure_storage_account_inventory_policies" {
  type = map(object({
    subscription_id     = optional(string, null)
    resource_group_name = string
    account_name        = string
    rules = list(object({
      name                  = string
      enabled               = optional(bool, true)
      destination           = string
      schedule              = string
      object_type           = string
      format                = string
      schema_fields         = list(string)
      include_snapshots     = optional(bool, false)
      include_blob_versions = optional(bool, false)
      include_deleted       = optional(bool, false)
      prefix_match          = optional(list(string), [])
      blob_types            = optional(list(string), ["blockBlob"])
      exclude_prefix        = optional(list(string), [])
    }))
  }))
  description = <<-EOT
    Map of blob inventory policies to create on storage accounts.
    Each policy defines one or more inventory rules that periodically write
    inventory reports (CSV or Parquet) to a destination container.

    Example:
      azure_storage_account_inventory_policies = {
        datalake_weekly = {
          resource_group_name = "rg-datalake"
          account_name        = "stdatalake001"
          rules = [
            {
              name          = "weekly-blob-inventory"
              destination   = "inventory-output"
              schedule      = "Weekly"
              object_type   = "Blob"
              format        = "Parquet"
              schema_fields = ["Name", "Creation-Time", "Content-Length", "BlobType", "AccessTier"]
              blob_types    = ["blockBlob"]
            }
          ]
        }
      }
  EOT
  default     = {}
}

locals {
  azure_storage_account_inventory_policies = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_inventory_policies, {}), var.azure_storage_account_inventory_policies)
  )
}

module "azure_storage_account_inventory_policies" {
  source   = "./modules/azure/storage_account_inventory_policy"
  for_each = local.azure_storage_account_inventory_policies

  depends_on = [module.azure_storage_accounts, module.azure_storage_account_containers]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  rules               = each.value.rules
  check_existance     = var.check_existance
}
