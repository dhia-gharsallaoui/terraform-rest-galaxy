# Source: azure-rest-api-specs
#   spec_path  : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : BlobContainers_Create (PUT, synchronous)
#   delete     : BlobContainers_Delete (DELETE, synchronous)

locals {
  api_version    = "2025-08-01"
  container_path = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/blobServices/default/containers/${var.container_name}"

  body = {
    properties = {
      publicAccess = var.public_access
    }
  }
}

resource "rest_resource" "container" {
  path             = local.container_path
  create_method    = "PUT"
  auth_ref         = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.publicAccess",
  ])
}
