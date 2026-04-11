# Integration test — configurations/storage_account_inventory.yaml (plan only)
# Run: terraform test -filter=tests/integration_config_storage_account_inventory.tftest.hcl
#
# Validates the YAML configuration without deploying to Azure.
# Checks ref: resolution, variable types, and dependency graph.
#
# IMPORTANT: Do NOT add a provider "rest" block here.
# The root module's provider config flows through automatically.

variable "access_token" {
  type      = string
  sensitive = true
  default   = "placeholder"
}

run "plan_storage_account_inventory" {
  command = plan

  variables {
    config_file     = "configurations/storage_account_inventory.yaml"
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = output.azure_values.azure_storage_accounts["datalake"] != null
    error_message = "Plan failed — storage account 'datalake' not found in output."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_inventory_policies["datalake-inventory"] != null
    error_message = "Plan failed — inventory policy 'datalake-inventory' not found in output."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_inventory_policies["datalake-inventory"].api_version == "2025-08-01"
    error_message = "Plan failed — api_version must be 2025-08-01."
  }
}
