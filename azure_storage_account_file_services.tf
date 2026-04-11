# ── Storage Account File Services ─────────────────────────────────────────────

variable "azure_storage_account_file_services" {
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
    share_delete_retention_policy = optional(object({
      enabled = optional(bool, true)
      days    = optional(number, 7)
    }), null)
    smb_versions                   = optional(list(string), null)
    smb_authentication_methods     = optional(list(string), null)
    smb_kerberos_ticket_encryption = optional(list(string), null)
    smb_channel_encryption         = optional(list(string), null)
    smb_multichannel_enabled       = optional(bool, null)
    nfs_v3_enabled                 = optional(bool, null)
    nfs_v4_1_enabled               = optional(bool, null)
    _tenant                        = optional(string, null)
    check_existance                = optional(bool, false)
  }))
  description = <<-EOT
    Map of file service configurations to apply to storage accounts. Each map key acts as
    the for_each identifier and must be unique within this configuration.

    Only one file service configuration exists per storage account (singleton pattern).
    The resource_group_name and account_name identify the parent storage account.

    Example:
      azure_storage_account_file_services = {
        app_files = {
          resource_group_name = "rg-myapp"
          account_name        = "mystorageaccount"
          share_delete_retention_policy = {
            enabled = true
            days    = 7
          }
          smb_versions               = ["SMB3.0", "SMB3.1.1"]
          smb_authentication_methods = ["Kerberos"]
          smb_channel_encryption     = ["AES-128-GCM", "AES-256-GCM"]
        }
      }
  EOT
  default     = {}
}

locals {
  azure_storage_account_file_services = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_file_services, {}), var.azure_storage_account_file_services)
  )
}

module "azure_storage_account_file_services" {
  source   = "./modules/azure/storage_account_file_service"
  for_each = local.azure_storage_account_file_services

  depends_on = [module.azure_storage_accounts]

  subscription_id                = try(each.value.subscription_id, var.subscription_id)
  resource_group_name            = each.value.resource_group_name
  account_name                   = each.value.account_name
  cors_rules                     = try(each.value.cors_rules, null)
  share_delete_retention_policy  = try(each.value.share_delete_retention_policy, null)
  smb_versions                   = try(each.value.smb_versions, null)
  smb_authentication_methods     = try(each.value.smb_authentication_methods, null)
  smb_kerberos_ticket_encryption = try(each.value.smb_kerberos_ticket_encryption, null)
  smb_channel_encryption         = try(each.value.smb_channel_encryption, null)
  smb_multichannel_enabled       = try(each.value.smb_multichannel_enabled, null)
  nfs_v3_enabled                 = try(each.value.nfs_v3_enabled, null)
  nfs_v4_1_enabled               = try(each.value.nfs_v4_1_enabled, null)
  check_existance                = try(each.value.check_existance, var.check_existance)
}
