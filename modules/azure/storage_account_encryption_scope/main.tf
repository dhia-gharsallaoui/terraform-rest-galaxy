# Source: azure-rest-api-specs
#   spec_path : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : EncryptionScopes_Put   (PUT, synchronous)
#   update     : EncryptionScopes_Patch (PATCH — same path, used by provider update)
#   delete     : No DELETE — set state = Disabled to deactivate.
#
# Encryption scopes cannot be deleted via the Azure API; set state = "Disabled"
# to decommission the scope without removing it from ARM.

locals {
  api_version = "2025-08-01"
  scope_path  = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/encryptionScopes/${var.encryption_scope_name}"

  # Key Vault properties — only included when source is Microsoft.KeyVault
  key_vault_properties = var.key_vault_key_uri != null ? {
    keyUri = var.key_vault_key_uri
  } : null

  properties = merge(
    { source = var.encryption_source },
    { state = var.state },
    var.require_infrastructure_encryption != null ? {
      requireInfrastructureEncryption = var.require_infrastructure_encryption
    } : {},
    local.key_vault_properties != null ? {
      keyVaultProperties = local.key_vault_properties
    } : {},
  )

  body = {
    properties = local.properties
  }
}

resource "rest_resource" "encryption_scope" {
  path            = local.scope_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.state",
    "properties.creationTime",
    "properties.lastModifiedTime",
    "properties.provisioningState",
  ])

  # PUT is synchronous — no poll_create / poll_update needed.
  # No poll_delete — Azure does not support deleting encryption scopes.
}
