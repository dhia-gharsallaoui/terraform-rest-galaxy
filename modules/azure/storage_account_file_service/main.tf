# Source: azure-rest-api-specs
#   spec_path  : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : FileServices_SetServiceProperties (PUT, synchronous singleton)
#   delete     : No DELETE — singleton service configuration. Resource is removed
#                from Terraform state only; the file service configuration persists
#                in Azure with its last applied settings.

locals {
  api_version   = "2025-08-01"
  file_svc_path = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/fileServices/default"

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

  # Share delete retention policy
  share_delete_retention_policy = var.share_delete_retention_policy != null ? merge(
    { enabled = var.share_delete_retention_policy.enabled },
    var.share_delete_retention_policy.days != null ? { days = var.share_delete_retention_policy.days } : {},
  ) : null

  # SMB protocol settings — build incrementally
  smb = (
    var.smb_versions != null ||
    var.smb_authentication_methods != null ||
    var.smb_kerberos_ticket_encryption != null ||
    var.smb_channel_encryption != null ||
    var.smb_multichannel_enabled != null
    ) ? merge(
    var.smb_versions != null ? { versions = join(";", var.smb_versions) } : {},
    var.smb_authentication_methods != null ? { authenticationMethods = join(";", var.smb_authentication_methods) } : {},
    var.smb_kerberos_ticket_encryption != null ? { kerberosTicketEncryption = join(";", var.smb_kerberos_ticket_encryption) } : {},
    var.smb_channel_encryption != null ? { channelEncryption = join(";", var.smb_channel_encryption) } : {},
    var.smb_multichannel_enabled != null ? { multichannel = { enabled = var.smb_multichannel_enabled } } : {},
  ) : null

  # NFS protocol settings
  nfs = (var.nfs_v3_enabled != null || var.nfs_v4_1_enabled != null) ? merge(
    var.nfs_v3_enabled != null ? { nfsV3 = { enabled = var.nfs_v3_enabled } } : {},
    var.nfs_v4_1_enabled != null ? { nfsV41 = { enabled = var.nfs_v4_1_enabled } } : {},
  ) : null

  # Protocol settings block
  protocol_settings = (local.smb != null || local.nfs != null) ? merge(
    local.smb != null ? { smb = local.smb } : {},
    local.nfs != null ? { nfs = local.nfs } : {},
  ) : null

  # Build properties object — only include explicitly set values
  properties = merge(
    local.cors != null ? { cors = local.cors } : {},
    local.share_delete_retention_policy != null ? { shareDeleteRetentionPolicy = local.share_delete_retention_policy } : {},
    local.protocol_settings != null ? { protocolSettings = local.protocol_settings } : {},
  )

  body = {
    properties = local.properties
  }
}

resource "rest_resource" "file_service" {
  path            = local.file_svc_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.provisioningState",
  ])

  # Singleton resource — no DELETE in the Azure REST API.
  # On terraform destroy, this resource is removed from state only.
  # The file service configuration persists in Azure with its last applied settings.
  # No poll_create / poll_update needed — PUT is synchronous for fileServices/default.
  lifecycle {
    # prevent_destroy = false is the default. Noted here for documentation clarity:
    # destroying this Terraform resource only removes it from state.
  }
}
