# Source: azure-rest-api-specs
#   spec_path  : storage/resource-manager/Microsoft.Storage
#   api_version: 2025-08-01
#   operation  : Queue_Create (PUT, synchronous)
#   delete     : Queue_Delete (DELETE, synchronous)

locals {
  api_version = "2025-08-01"
  queue_path  = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.account_name}/queueServices/default/queues/${var.queue_name}"

  properties = merge(
    {},
    var.metadata != null ? { metadata = var.metadata } : {},
  )

  body = { properties = local.properties }
}

resource "rest_resource" "queue" {
  path            = local.queue_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.approximateMessageCount",
    "properties.metadata",
  ])

  # Queue creation is synchronous — no poll_create / poll_update needed.
  # DELETE is also synchronous — no poll_delete needed.
}
