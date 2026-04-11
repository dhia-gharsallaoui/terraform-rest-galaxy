# Source: azure-rest-api-specs
#   spec_path : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : ManagementPolicies_CreateOrUpdate (PUT, synchronous)
#   delete     : ManagementPolicies_Delete         (DELETE, synchronous)
#
# Singleton resource — the policy name is always "default".
# Only one management policy is permitted per storage account.

locals {
  api_version = "2025-08-01"
  policy_path = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/managementPolicies/default"

  # ── Build ARM rules from flat HCL variables ───────────────────────────────
  # Maps the terraform-idiomatic snake_case inputs to the ARM JSON camelCase schema.
  arm_rules = [
    for rule in var.rules : {
      name    = rule.name
      enabled = rule.enabled
      type    = "Lifecycle"
      definition = {
        filters = rule.filters != null ? merge(
          { blobTypes = rule.filters.blob_types },
          length(rule.filters.prefix_match) > 0 ? { prefixMatch = rule.filters.prefix_match } : {},
          length(rule.filters.blob_index_match) > 0 ? {
            blobIndexMatch = [
              for m in rule.filters.blob_index_match : {
                name  = m.name
                op    = m.operation
                value = m.value
              }
            ]
          } : {},
        ) : { blobTypes = ["blockBlob"] }

        actions = merge(
          rule.actions.base_blob != null ? {
            baseBlob = merge(
              rule.actions.base_blob.tier_to_cool_after_days_since_modification_greater_than != null ? {
                tierToCool = { daysAfterModificationGreaterThan = rule.actions.base_blob.tier_to_cool_after_days_since_modification_greater_than }
              } : {},
              rule.actions.base_blob.tier_to_cool_after_days_since_last_access_time_greater_than != null ? {
                tierToCool = { daysAfterLastAccessTimeGreaterThan = rule.actions.base_blob.tier_to_cool_after_days_since_last_access_time_greater_than }
              } : {},
              rule.actions.base_blob.tier_to_cold_after_days_since_modification_greater_than != null ? {
                tierToCold = { daysAfterModificationGreaterThan = rule.actions.base_blob.tier_to_cold_after_days_since_modification_greater_than }
              } : {},
              rule.actions.base_blob.tier_to_cold_after_days_since_last_access_time_greater_than != null ? {
                tierToCold = { daysAfterLastAccessTimeGreaterThan = rule.actions.base_blob.tier_to_cold_after_days_since_last_access_time_greater_than }
              } : {},
              rule.actions.base_blob.tier_to_archive_after_days_since_modification_greater_than != null ? {
                tierToArchive = { daysAfterModificationGreaterThan = rule.actions.base_blob.tier_to_archive_after_days_since_modification_greater_than }
              } : {},
              rule.actions.base_blob.tier_to_archive_after_days_since_last_access_time_greater_than != null ? {
                tierToArchive = { daysAfterLastAccessTimeGreaterThan = rule.actions.base_blob.tier_to_archive_after_days_since_last_access_time_greater_than }
              } : {},
              rule.actions.base_blob.delete_after_days_since_modification_greater_than != null ? {
                delete = { daysAfterModificationGreaterThan = rule.actions.base_blob.delete_after_days_since_modification_greater_than }
              } : {},
              rule.actions.base_blob.delete_after_days_since_last_access_time_greater_than != null ? {
                delete = { daysAfterLastAccessTimeGreaterThan = rule.actions.base_blob.delete_after_days_since_last_access_time_greater_than }
              } : {},
              rule.actions.base_blob.enable_auto_tier_to_hot_from_cool != null ? {
                enableAutoTierToHotFromCool = rule.actions.base_blob.enable_auto_tier_to_hot_from_cool
              } : {},
            )
          } : {},
          rule.actions.snapshot != null ? {
            snapshot = merge(
              rule.actions.snapshot.change_tier_to_cool_after_days_since_creation != null ? {
                tierToCool = { daysAfterCreationGreaterThan = rule.actions.snapshot.change_tier_to_cool_after_days_since_creation }
              } : {},
              rule.actions.snapshot.change_tier_to_cold_after_days_since_creation != null ? {
                tierToCold = { daysAfterCreationGreaterThan = rule.actions.snapshot.change_tier_to_cold_after_days_since_creation }
              } : {},
              rule.actions.snapshot.change_tier_to_archive_after_days_since_creation != null ? {
                tierToArchive = { daysAfterCreationGreaterThan = rule.actions.snapshot.change_tier_to_archive_after_days_since_creation }
              } : {},
              rule.actions.snapshot.delete_after_days_since_creation_greater_than != null ? {
                delete = { daysAfterCreationGreaterThan = rule.actions.snapshot.delete_after_days_since_creation_greater_than }
              } : {},
            )
          } : {},
          rule.actions.version != null ? {
            version = merge(
              rule.actions.version.change_tier_to_cool_after_days_since_creation != null ? {
                tierToCool = { daysAfterCreationGreaterThan = rule.actions.version.change_tier_to_cool_after_days_since_creation }
              } : {},
              rule.actions.version.change_tier_to_cold_after_days_since_creation != null ? {
                tierToCold = { daysAfterCreationGreaterThan = rule.actions.version.change_tier_to_cold_after_days_since_creation }
              } : {},
              rule.actions.version.change_tier_to_archive_after_days_since_creation != null ? {
                tierToArchive = { daysAfterCreationGreaterThan = rule.actions.version.change_tier_to_archive_after_days_since_creation }
              } : {},
              rule.actions.version.delete_after_days_since_creation != null ? {
                delete = { daysAfterCreationGreaterThan = rule.actions.version.delete_after_days_since_creation }
              } : {},
            )
          } : {},
        )
      }
    }
  ]

  body = {
    properties = {
      policy = {
        rules = local.arm_rules
      }
    }
  }
}

resource "rest_resource" "management_policy" {
  path            = local.policy_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.lastModifiedTime",
    "properties.policy.rules",
  ])

  # PUT and DELETE are synchronous — no polling needed.
}
