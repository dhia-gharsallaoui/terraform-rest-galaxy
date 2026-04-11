# Source: azure-rest-api-specs
#   spec_path : resources/resource-manager/Microsoft.Resources/resources
#   api_version: 2025-04-01
#   operation  : Providers_Register   (POST, synchronous)
#   delete     : Providers_Unregister (POST, synchronous)
#
# NOTE: Register and unregister are both POST operations — there is no
# PUT/GET lifecycle. We use rest_operation for the registration and a
# separate rest_operation for cleanup (unregister on destroy).

locals {
  api_version   = "2025-04-01"
  register_path = "/subscriptions/${var.subscription_id}/providers/${var.resource_provider_namespace}/register"
  provider_path = "/subscriptions/${var.subscription_id}/providers/${var.resource_provider_namespace}"
}

resource "rest_operation" "register" {
  path             = local.register_path
  method           = "POST"
  auth_ref         = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  # POST register has no required body; the optional body is for third-party consent only.

  # Poll the provider GET endpoint until registrationState becomes "Registered".
  poll = {
    status_locator    = "body.registrationState"
    url_locator       = "exact.https://management.azure.com${local.provider_path}?api-version=${local.api_version}"
    default_delay_sec = 10
    status = {
      success = "Registered"
      pending = ["Registering"]
    }
  }

  delete_path   = var.skip_deregister ? null : "/subscriptions/${var.subscription_id}/providers/${var.resource_provider_namespace}/unregister"
  delete_method = var.skip_deregister ? null : "POST"
}
