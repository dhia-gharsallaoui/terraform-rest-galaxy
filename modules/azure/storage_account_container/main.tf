# Source: azure-rest-api-specs
#   spec_path  : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : BlobContainers_Create (PUT, synchronous)
#   delete     : BlobContainers_Delete (DELETE, synchronous)

locals {
  api_version    = "2025-08-01"
  container_path = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/blobServices/default/containers/${var.container_name}"

  properties = merge(
    { publicAccess = var.public_access },
    var.metadata != null ? { metadata = var.metadata } : {},
    var.default_encryption_scope != null ? { defaultEncryptionScope = var.default_encryption_scope } : {},
    var.deny_encryption_scope_override != null ? { denyEncryptionScopeOverride = var.deny_encryption_scope_override } : {},
    var.enable_nfs_v3_all_squash != null ? { enableNfsV3AllSquash = var.enable_nfs_v3_all_squash } : {},
    var.enable_nfs_v3_root_squash != null ? { enableNfsV3RootSquash = var.enable_nfs_v3_root_squash } : {},
    var.immutable_storage_with_versioning_enabled != null ? {
      immutableStorageWithVersioning = { enabled = var.immutable_storage_with_versioning_enabled }
    } : {},
  )

  body = { properties = local.properties }
}

resource "rest_resource" "container" {
  path            = local.container_path
  create_method   = "PUT"
  check_existance = var.check_existance
  auth_ref        = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.publicAccess",
    "properties.etag",
    "properties.defaultEncryptionScope",
    "properties.denyEncryptionScopeOverride",
    "properties.hasLegalHold",
    "properties.hasImmutabilityPolicy",
    "properties.leaseStatus",
    "properties.leaseState",
    "properties.lastModifiedTime",
    "properties.remainingRetentionDays",
  ])
}
