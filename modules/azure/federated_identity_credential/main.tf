# Source: azure-rest-api-specs
#   spec_path : msi/resource-manager/Microsoft.ManagedIdentity/ManagedIdentity
#   api_version: 2024-11-30
#   operation  : FederatedIdentityCredentials_CreateOrUpdate  (PUT, synchronous)
#   delete     : FederatedIdentityCredentials_Delete          (DELETE, synchronous)

locals {
  api_version = "2024-11-30"
  fic_path    = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${var.identity_name}/federatedIdentityCredentials/${var.federated_credential_name}"
}

resource "rest_resource" "federated_identity_credential" {
  path            = local.fic_path
  create_method   = "PUT"
  check_existance = var.check_existance
  auth_ref        = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = {
    properties = {
      issuer    = var.issuer
      subject   = var.subject
      audiences = var.audiences
    }
  }

  output_attrs = toset([
    "properties.issuer",
    "properties.subject",
    "properties.audiences",
  ])
}
