# Integration test — configurations/storage_account_sftp.yaml (plan only)
# Run: terraform test -filter=tests/integration_config_storage_account_sftp.tftest.hcl
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

run "plan_storage_account_sftp" {
  command = plan

  variables {
    config_file     = "configurations/storage_account_sftp.yaml"
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = output.azure_values.azure_storage_accounts["sftp"] != null
    error_message = "Plan failed — storage account 'sftp' not found in output."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_local_users["blob-uploader"] != null
    error_message = "Plan failed — local user 'blob-uploader' not found in output."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_local_users["file-reader"] != null
    error_message = "Plan failed — local user 'file-reader' not found in output."
  }

  assert {
    condition     = output.azure_values.azure_storage_account_local_users["blob-uploader"].name == "blob-uploader"
    error_message = "Plan failed — blob-uploader name output does not echo input."
  }
}
