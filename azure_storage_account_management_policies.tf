# ── Storage Account Management Policies ───────────────────────────────────────

variable "azure_storage_account_management_policies" {
  type = map(object({
    subscription_id     = optional(string, null)
    resource_group_name = string
    account_name        = string
    rules = list(object({
      name    = string
      enabled = optional(bool, true)
      filters = optional(object({
        blob_types   = list(string)
        prefix_match = optional(list(string), [])
        blob_index_match = optional(list(object({
          name      = string
          operation = optional(string, "==")
          value     = string
        })), [])
      }))
      actions = object({
        base_blob = optional(object({
          tier_to_cool_after_days_since_modification_greater_than        = optional(number, null)
          tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number, null)
          tier_to_cold_after_days_since_modification_greater_than        = optional(number, null)
          tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number, null)
          tier_to_archive_after_days_since_modification_greater_than     = optional(number, null)
          tier_to_archive_after_days_since_last_access_time_greater_than = optional(number, null)
          delete_after_days_since_modification_greater_than              = optional(number, null)
          delete_after_days_since_last_access_time_greater_than          = optional(number, null)
          enable_auto_tier_to_hot_from_cool                              = optional(bool, null)
        }), null)
        snapshot = optional(object({
          change_tier_to_cool_after_days_since_creation    = optional(number, null)
          change_tier_to_cold_after_days_since_creation    = optional(number, null)
          change_tier_to_archive_after_days_since_creation = optional(number, null)
          delete_after_days_since_creation_greater_than    = optional(number, null)
        }), null)
        version = optional(object({
          change_tier_to_cool_after_days_since_creation    = optional(number, null)
          change_tier_to_cold_after_days_since_creation    = optional(number, null)
          change_tier_to_archive_after_days_since_creation = optional(number, null)
          delete_after_days_since_creation                 = optional(number, null)
        }), null)
      })
    }))
    check_existance = optional(bool, null)
  }))
  description = <<-EOT
    Map of storage account management policy instances to create. Each map key
    acts as the for_each identifier and must be unique within this configuration.
    Only one management policy (named "default") is allowed per storage account.

    Example:
      azure_storage_account_management_policies = {
        datalake = {
          resource_group_name = "rg-data"
          account_name        = "mydatalake"
          rules = [
            {
              name    = "lifecycle-hot-to-cold"
              enabled = true
              filters = {
                blob_types   = ["blockBlob"]
                prefix_match = ["raw/"]
              }
              actions = {
                base_blob = {
                  tier_to_cool_after_days_since_modification_greater_than    = 30
                  tier_to_archive_after_days_since_modification_greater_than = 180
                  delete_after_days_since_modification_greater_than          = 1825
                }
              }
            }
          ]
        }
      }
  EOT
  default     = {}
}

locals {
  azure_storage_account_management_policies = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_management_policies, {}), var.azure_storage_account_management_policies)
  )
}

module "azure_storage_account_management_policies" {
  source   = "./modules/azure/storage_account_management_policy"
  for_each = local.azure_storage_account_management_policies

  depends_on = [module.azure_storage_accounts]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  rules               = each.value.rules
  check_existance     = try(each.value.check_existance, var.check_existance)
}
