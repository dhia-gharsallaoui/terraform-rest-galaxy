# Integration test — configurations/storage_account_lifecycle.yaml (plan only)
# Run: terraform test -filter=tests/integration_config_storage_account_lifecycle.tftest.hcl
#
# Validates the lifecycle configuration YAML without deploying to Azure.
# Checks ref: resolution, variable types, and dependency graph.
#
# IMPORTANT: Do NOT add a provider "rest" block here.
# The root module's provider config flows through automatically.
# Adding one causes "Provider type mismatch" errors with unit tests.

variable "access_token" {
  type      = string
  sensitive = true
  default   = "placeholder"
}

variable "subscription_id" {
  type    = string
  default = "00000000-0000-0000-0000-000000000000"
}

run "plan_storage_account_lifecycle" {
  command = plan

  variables {
    config_file     = "configurations/storage_account_lifecycle.yaml"
    subscription_id = var.subscription_id
  }

  assert {
    condition     = output.azure_values.azure_storage_account_management_policies["datalake"] != null
    error_message = "Plan failed — management policy 'datalake' not found in output."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_management_policies["datalake"].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-datalake-prod/providers/Microsoft.Storage/storageAccounts/datalakeprod001/managementPolicies/default"
    error_message = "Plan failed — management policy id is not correctly formed."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_management_policies["datalake"].api_version == "2025-08-01"
    error_message = "Plan failed — api_version must be 2025-08-01."
  }
}
