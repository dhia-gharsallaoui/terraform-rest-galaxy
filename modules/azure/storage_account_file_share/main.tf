# Source: azure-rest-api-specs
#   spec_path  : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : FileShares_Create (PUT, synchronous)
#   delete     : FileShares_Delete (DELETE, synchronous)

locals {
  api_version = "2025-08-01"
  share_path  = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/fileServices/default/shares/${var.share_name}"

  # signedIdentifiers — translate to ARM field names
  signed_identifiers = var.signed_identifiers != null ? [
    for si in var.signed_identifiers : merge(
      { id = si.id },
      si.access_policy != null ? {
        accessPolicy = {
          for k, v in {
            startTime  = try(si.access_policy.start_time, null)
            expiryTime = try(si.access_policy.expiry_time, null)
            permission = try(si.access_policy.permission, null)
          } : k => v if v != null
        }
      } : {}
    )
  ] : null

  properties = merge(
    { shareQuota = var.share_quota },
    var.access_tier != null ? { accessTier = var.access_tier } : {},
    var.enabled_protocols != null ? { enabledProtocols = var.enabled_protocols } : {},
    var.root_squash != null ? { rootSquash = var.root_squash } : {},
    var.metadata != null ? { metadata = var.metadata } : {},
    local.signed_identifiers != null ? { signedIdentifiers = local.signed_identifiers } : {},
  )

  body = { properties = local.properties }
}

resource "rest_resource" "file_share" {
  path            = local.share_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.shareQuota",
    "properties.accessTier",
    "properties.enabledProtocols",
    "properties.provisioningState",
  ])

  # enabledProtocols is immutable after creation — Azure rejects updates.
  # Force destroy+create on change instead of an in-place update that would fail.
  force_new_attrs = toset([
    "properties.enabledProtocols",
  ])

  # File share creation is synchronous — no poll_create / poll_update needed.
  # DELETE is also synchronous — no poll_delete needed.
}
