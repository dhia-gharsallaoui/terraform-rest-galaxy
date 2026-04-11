# ── Storage Account Blob Services ─────────────────────────────────────────────

variable "azure_storage_account_blob_services" {
  type = map(object({
    subscription_id     = optional(string, null)
    resource_group_name = string
    account_name        = string
    cors_rules = optional(list(object({
      allowed_origins    = list(string)
      allowed_methods    = list(string)
      allowed_headers    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), null)
    delete_retention_policy = optional(object({
      enabled                = optional(bool, true)
      days                   = optional(number, 7)
      allow_permanent_delete = optional(bool, false)
    }), null)
    container_delete_retention_policy = optional(object({
      enabled = optional(bool, true)
      days    = optional(number, 7)
    }), null)
    is_versioning_enabled                    = optional(bool, null)
    change_feed_enabled                      = optional(bool, null)
    change_feed_retention_in_days            = optional(number, null)
    restore_policy_enabled                   = optional(bool, null)
    restore_policy_days                      = optional(number, null)
    last_access_time_tracking_enabled        = optional(bool, null)
    last_access_tracking_granularity_in_days = optional(number, null)
    automatic_snapshot_policy_enabled        = optional(bool, null)
    default_service_version                  = optional(string, null)
    _tenant                                  = optional(string, null)
    check_existance                          = optional(bool, false)
  }))
  description = <<-EOT
    Map of blob service configurations to apply to storage accounts. Each map key acts as
    the for_each identifier and must be unique within this configuration.

    Only one blob service configuration exists per storage account (singleton pattern).
    The resource_group_name and account_name identify the parent storage account.

    Example:
      azure_storage_account_blob_services = {
        app_blobs = {
          resource_group_name = "rg-myapp"
          account_name        = "mystorageaccount"
          delete_retention_policy = {
            enabled = true
            days    = 7
          }
          is_versioning_enabled = true
          change_feed_enabled   = true
        }
      }
  EOT
  default     = {}
}

locals {
  azure_storage_account_blob_services = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_blob_services, {}), var.azure_storage_account_blob_services)
  )
}

module "azure_storage_account_blob_services" {
  source   = "./modules/azure/storage_account_blob_service"
  for_each = local.azure_storage_account_blob_services

  depends_on = [module.azure_storage_accounts]

  subscription_id                          = try(each.value.subscription_id, var.subscription_id)
  resource_group_name                      = each.value.resource_group_name
  account_name                             = each.value.account_name
  cors_rules                               = try(each.value.cors_rules, null)
  delete_retention_policy                  = try(each.value.delete_retention_policy, null)
  container_delete_retention_policy        = try(each.value.container_delete_retention_policy, null)
  is_versioning_enabled                    = try(each.value.is_versioning_enabled, null)
  change_feed_enabled                      = try(each.value.change_feed_enabled, null)
  change_feed_retention_in_days            = try(each.value.change_feed_retention_in_days, null)
  restore_policy_enabled                   = try(each.value.restore_policy_enabled, null)
  restore_policy_days                      = try(each.value.restore_policy_days, null)
  last_access_time_tracking_enabled        = try(each.value.last_access_time_tracking_enabled, null)
  last_access_tracking_granularity_in_days = try(each.value.last_access_tracking_granularity_in_days, null)
  automatic_snapshot_policy_enabled        = try(each.value.automatic_snapshot_policy_enabled, null)
  default_service_version                  = try(each.value.default_service_version, null)
  check_existance                          = try(each.value.check_existance, var.check_existance)
}
