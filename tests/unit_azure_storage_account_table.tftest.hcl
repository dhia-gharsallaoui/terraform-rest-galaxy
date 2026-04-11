# Unit test — modules/azure/storage_account_table
# Tests the sub-module in isolation (plan only).
# Run: terraform test -filter=tests/unit_azure_storage_account_table.tftest.hcl

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

# ── Minimum ────────────────────────────────────────────────────────────────────

run "plan_minimum" {
  command = plan

  module {
    source = "./modules/azure/storage_account_table"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunittest001"
    table_name          = "MyTable"
  }

  assert {
    condition     = output.name == "MyTable"
    error_message = "name must echo table_name."
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunittest001/tableServices/default/tables/MyTable"
    error_message = "id must be the fully-qualified ARM resource ID."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version must return the pinned API version."
  }
}

# ── With signed identifiers ───────────────────────────────────────────────────

run "plan_with_signed_identifiers" {
  command = plan

  module {
    source = "./modules/azure/storage_account_table"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunittest001"
    table_name          = "EventsTable"
    signed_identifiers = [
      {
        id = "readpolicy"
        access_policy = {
          start_time  = "2025-01-01T00:00:00Z"
          expiry_time = "2026-01-01T00:00:00Z"
          permission  = "r"
        }
      }
    ]
  }

  assert {
    condition     = output.name == "EventsTable"
    error_message = "name must echo table_name."
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunittest001/tableServices/default/tables/EventsTable"
    error_message = "id must be the fully-qualified ARM resource ID."
  }
}
