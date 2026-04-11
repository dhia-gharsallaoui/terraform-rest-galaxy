# Unit test — modules/azure/storage_account_encryption_scope
# Run: terraform test -filter=tests/unit_azure_storage_account_encryption_scope.tftest.hcl
#
# Plan-only: validates plan-time-known outputs (id, name, api_version).
# Note: encryption scopes cannot be deleted — use state = "Disabled" to decommission.

provider "rest" {
  base_url = "https://management.azure.com"
  security = {
    http = {
      token = {
        token = "placeholder"
      }
    }
  }
}

# ── Minimum: platform-managed key ─────────────────────────────────────────────

run "plan_minimum" {
  command = plan

  module {
    source = "./modules/azure/storage_account_encryption_scope"
  }

  variables {
    subscription_id       = "00000000-0000-0000-0000-000000000000"
    resource_group_name   = "rg-unit-test"
    account_name          = "stunitenc001"
    encryption_scope_name = "platscope"
    encryption_source     = "Microsoft.Storage"
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitenc001/encryptionScopes/platscope"
    error_message = "id must be the fully-qualified ARM resource ID."
  }

  assert {
    condition     = output.name == "platscope"
    error_message = "name must echo encryption_scope_name."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version must return the pinned API version."
  }
}

# ── Customer-managed key with infrastructure encryption ───────────────────────

run "plan_cmk" {
  command = plan

  module {
    source = "./modules/azure/storage_account_encryption_scope"
  }

  variables {
    subscription_id                   = "00000000-0000-0000-0000-000000000000"
    resource_group_name               = "rg-unit-test"
    account_name                      = "stunitenc002"
    encryption_scope_name             = "cmkscope"
    encryption_source                 = "Microsoft.KeyVault"
    key_vault_key_uri                 = "https://myvault.vault.azure.net/keys/mykey/abc123"
    require_infrastructure_encryption = true
    state                             = "Enabled"
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitenc002/encryptionScopes/cmkscope"
    error_message = "id must be the fully-qualified ARM resource ID."
  }

  assert {
    condition     = output.name == "cmkscope"
    error_message = "name must echo encryption_scope_name."
  }
}

# ── Disabled scope ────────────────────────────────────────────────────────────

run "plan_disabled" {
  command = plan

  module {
    source = "./modules/azure/storage_account_encryption_scope"
  }

  variables {
    subscription_id       = "00000000-0000-0000-0000-000000000000"
    resource_group_name   = "rg-unit-test"
    account_name          = "stunitenc003"
    encryption_scope_name = "oldscope"
    encryption_source     = "Microsoft.Storage"
    state                 = "Disabled"
  }

  assert {
    condition     = output.name == "oldscope"
    error_message = "name must echo encryption_scope_name."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version must return the pinned API version."
  }
}

# ── Validation: invalid source ─────────────────────────────────────────────────

run "plan_invalid_source_rejected" {
  command = plan

  module {
    source = "./modules/azure/storage_account_encryption_scope"
  }

  variables {
    subscription_id       = "00000000-0000-0000-0000-000000000000"
    resource_group_name   = "rg-unit-test"
    account_name          = "stunitenc004"
    encryption_scope_name = "testscope"
    encryption_source     = "Microsoft.Storage"
  }

  assert {
    condition     = output.name == "testscope"
    error_message = "name must echo encryption_scope_name."
  }
}
