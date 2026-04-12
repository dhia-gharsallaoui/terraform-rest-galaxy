# ── Storage Account Containers ────────────────────────────────────────────────

variable "azure_storage_account_containers" {
  type = map(object({
    subscription_id                           = optional(string, null)
    resource_group_name                       = string
    account_name                              = string
    container_name                            = string
    public_access                             = optional(string, "None")
    metadata                                  = optional(map(string), null)
    default_encryption_scope                  = optional(string, null)
    deny_encryption_scope_override            = optional(bool, null)
    enable_nfs_v3_all_squash                  = optional(bool, null)
    enable_nfs_v3_root_squash                 = optional(bool, null)
    immutable_storage_with_versioning_enabled = optional(bool, null)
    _tenant                                   = optional(string, null)
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

  subscription_id                           = try(each.value.subscription_id, var.subscription_id)
  resource_group_name                       = each.value.resource_group_name
  account_name                              = each.value.account_name
  container_name                            = each.value.container_name
  public_access                             = try(each.value.public_access, "None")
  metadata                                  = try(each.value.metadata, null)
  default_encryption_scope                  = try(each.value.default_encryption_scope, null)
  deny_encryption_scope_override            = try(each.value.deny_encryption_scope_override, null)
  enable_nfs_v3_all_squash                  = try(each.value.enable_nfs_v3_all_squash, null)
  enable_nfs_v3_root_squash                 = try(each.value.enable_nfs_v3_root_squash, null)
  immutable_storage_with_versioning_enabled = try(each.value.immutable_storage_with_versioning_enabled, null)
  check_existance                           = var.check_existance
  auth_ref                                  = try(each.value._tenant, null)
}
