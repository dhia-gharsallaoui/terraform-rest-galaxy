# Unit test — modules/azure/storage_account_management_policy
# Run: terraform test -filter=tests/unit_azure_storage_account_management_policy.tftest.hcl
#
# Plan-only: validates plan-time-known outputs (id, api_version).
# The management policy is a singleton — only one allowed per storage account,
# always named "default".

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

# ── Minimum: single delete rule ───────────────────────────────────────────────

run "plan_minimum" {
  command = plan

  module {
    source = "./modules/azure/storage_account_management_policy"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitpolicy001"
    rules = [
      {
        name = "delete-old-blobs"
        filters = {
          blob_types = ["blockBlob"]
        }
        actions = {
          base_blob = {
            delete_after_days_since_last_access_time_greater_than = 90
          }
        }
      }
    ]
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitpolicy001/managementPolicies/default"
    error_message = "id must be the fully-qualified ARM resource ID with singleton name 'default'."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version must return the pinned API version."
  }
}

# ── Complete: multi-tier data lake lifecycle ───────────────────────────────────

run "plan_complete" {
  command = plan

  module {
    source = "./modules/azure/storage_account_management_policy"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitpolicy002"
    rules = [
      {
        name    = "tier-raw-blobs"
        enabled = true
        filters = {
          blob_types   = ["blockBlob"]
          prefix_match = ["raw/", "processed/"]
        }
        actions = {
          base_blob = {
            tier_to_cool_after_days_since_modification_greater_than    = 30
            tier_to_archive_after_days_since_modification_greater_than = 180
            delete_after_days_since_modification_greater_than          = 1825
          }
          snapshot = {
            change_tier_to_archive_after_days_since_creation = 90
            delete_after_days_since_creation_greater_than    = 365
          }
          version = {
            change_tier_to_archive_after_days_since_creation = 90
            delete_after_days_since_creation                 = 365
          }
        }
      },
      {
        name    = "delete-temp"
        enabled = true
        filters = {
          blob_types   = ["blockBlob"]
          prefix_match = ["tmp/"]
        }
        actions = {
          base_blob = {
            delete_after_days_since_last_access_time_greater_than = 7
          }
        }
      }
    ]
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitpolicy002/managementPolicies/default"
    error_message = "id must be the fully-qualified ARM resource ID."
  }
}

# ── Disabled rule ─────────────────────────────────────────────────────────────

run "plan_disabled_rule" {
  command = plan

  module {
    source = "./modules/azure/storage_account_management_policy"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitpolicy003"
    rules = [
      {
        name    = "disabled-rule"
        enabled = false
        filters = {
          blob_types = ["blockBlob"]
        }
        actions = {
          base_blob = {
            delete_after_days_since_modification_greater_than = 365
          }
        }
      }
    ]
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version must return the pinned API version."
  }
}
