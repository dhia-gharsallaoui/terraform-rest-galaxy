# Source: azure-rest-api-specs
#   spec_path  : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : BlobServices_SetServiceProperties (PUT, synchronous singleton)
#   delete     : No DELETE — singleton service configuration. Resource is removed
#                from Terraform state only; the blob service configuration persists
#                in Azure with its last applied settings.

locals {
  api_version   = "2025-08-01"
  blob_svc_path = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/blobServices/default"

  # CORS rules — translate to ARM field names
  cors = var.cors_rules != null ? {
    corsRules = [for rule in var.cors_rules : {
      allowedOrigins  = rule.allowed_origins
      allowedMethods  = rule.allowed_methods
      allowedHeaders  = rule.allowed_headers
      exposedHeaders  = rule.exposed_headers
      maxAgeInSeconds = rule.max_age_in_seconds
    }]
  } : null

  # Delete retention policy block
  delete_retention_policy = var.delete_retention_policy != null ? merge(
    { enabled = var.delete_retention_policy.enabled },
    var.delete_retention_policy.days != null ? { days = var.delete_retention_policy.days } : {},
    var.delete_retention_policy.allow_permanent_delete != null ? { allowPermanentDelete = var.delete_retention_policy.allow_permanent_delete } : {},
  ) : null

  # Container delete retention policy block
  container_delete_retention_policy = var.container_delete_retention_policy != null ? merge(
    { enabled = var.container_delete_retention_policy.enabled },
    var.container_delete_retention_policy.days != null ? { days = var.container_delete_retention_policy.days } : {},
  ) : null

  # Change feed block
  change_feed = (var.change_feed_enabled != null || var.change_feed_retention_in_days != null) ? merge(
    var.change_feed_enabled != null ? { enabled = var.change_feed_enabled } : {},
    var.change_feed_retention_in_days != null ? { retentionInDays = var.change_feed_retention_in_days } : {},
  ) : null

  # Restore policy block
  restore_policy = (var.restore_policy_enabled != null || var.restore_policy_days != null) ? merge(
    var.restore_policy_enabled != null ? { enabled = var.restore_policy_enabled } : {},
    var.restore_policy_days != null ? { days = var.restore_policy_days } : {},
  ) : null

  # Last access time tracking policy block
  last_access_time_tracking_policy = (var.last_access_time_tracking_enabled != null || var.last_access_tracking_granularity_in_days != null) ? merge(
    var.last_access_time_tracking_enabled != null ? { enable = var.last_access_time_tracking_enabled } : {},
    var.last_access_tracking_granularity_in_days != null ? { trackingGranularityInDays = var.last_access_tracking_granularity_in_days } : {},
  ) : null

  # Build properties object — only include explicitly set values
  properties = merge(
    local.cors != null ? { cors = local.cors } : {},
    local.delete_retention_policy != null ? { deleteRetentionPolicy = local.delete_retention_policy } : {},
    local.container_delete_retention_policy != null ? { containerDeleteRetentionPolicy = local.container_delete_retention_policy } : {},
    var.is_versioning_enabled != null ? { isVersioningEnabled = var.is_versioning_enabled } : {},
    local.change_feed != null ? { changeFeed = local.change_feed } : {},
    local.restore_policy != null ? { restorePolicy = local.restore_policy } : {},
    local.last_access_time_tracking_policy != null ? { lastAccessTimeTrackingPolicy = local.last_access_time_tracking_policy } : {},
    var.automatic_snapshot_policy_enabled != null ? { automaticSnapshotPolicyEnabled = var.automatic_snapshot_policy_enabled } : {},
    var.default_service_version != null ? { defaultServiceVersion = var.default_service_version } : {},
  )

  body = {
    properties = local.properties
  }
}

resource "rest_resource" "blob_service" {
  path            = local.blob_svc_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.provisioningState",
    "sku.name",
  ])

  # Singleton resource — no DELETE in the Azure REST API.
  # On terraform destroy, this resource is removed from state only.
  # The blob service configuration persists in Azure with its last applied settings.
  # No poll_create / poll_update needed — PUT is synchronous for blobServices/default.
  lifecycle {
    # prevent_destroy = false is the default. Noted here for documentation clarity:
    # destroying this Terraform resource only removes it from state.
  }
}
