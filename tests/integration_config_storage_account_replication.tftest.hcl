# Integration test — configurations/storage_account_replication.yaml (plan only)
# Run: terraform test -filter=tests/integration_config_storage_account_replication.tftest.hcl
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

run "plan_storage_account_replication" {
  command = plan

  variables {
    config_file     = "configurations/storage_account_replication.yaml"
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = output.azure_values.azure_storage_accounts["source"] != null
    error_message = "Plan failed — source storage account not found in output."
  }

  assert {
    condition     = output.azure_values.azure_storage_accounts["destination"] != null
    error_message = "Plan failed — destination storage account not found in output."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_object_replication_policies["prod-to-dr"] != null
    error_message = "Plan failed — object replication policy 'prod-to-dr' not found in output."
  }
}
