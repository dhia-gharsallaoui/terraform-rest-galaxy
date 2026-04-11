# Integration test — configurations/storage_account_encryption_scopes.yaml (plan only)
# Run: terraform test -filter=tests/integration_config_storage_account_encryption_scopes.tftest.hcl
#
# Validates the encryption scopes configuration YAML without deploying to Azure.
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

run "plan_storage_account_encryption_scopes" {
  command = plan

  variables {
    config_file     = "configurations/storage_account_encryption_scopes.yaml"
    subscription_id = var.subscription_id
  }

  assert {
    condition     = output.azure_values.azure_storage_account_encryption_scopes["platform"] != null
    error_message = "Plan failed — encryption scope 'platform' not found in output."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_encryption_scopes["platform"].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-storage-prod/providers/Microsoft.Storage/storageAccounts/mystorageaccount/encryptionScopes/platscope"
    error_message = "Plan failed — platform encryption scope id is not correctly formed."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_encryption_scopes["cmk"] != null
    error_message = "Plan failed — encryption scope 'cmk' not found in output."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_encryption_scopes["cmk"].name == "cmkscope"
    error_message = "Plan failed — cmk encryption scope name must echo input."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_encryption_scopes["platform"].api_version == "2025-08-01"
    error_message = "Plan failed — api_version must be 2025-08-01."
  }
}
