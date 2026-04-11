# Unit test — modules/azure/storage_account_blob_service
# Plan-only: validates the singleton ARM path output known at plan time.
# Run: terraform test -filter=tests/unit_azure_storage_account_blob_service.tftest.hcl

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

# ── Minimum fields ─────────────────────────────────────────────────────────────

run "plan_minimum" {
  command = plan

  module {
    source = "./modules/azure/storage_account_blob_service"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitblob001"
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitblob001/blobServices/default"
    error_message = "id output must be the fully-qualified ARM singleton path."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version output must return the pinned API version."
  }
}

# ── Soft delete enabled ────────────────────────────────────────────────────────

run "plan_soft_delete" {
  command = plan

  module {
    source = "./modules/azure/storage_account_blob_service"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitblob002"
    delete_retention_policy = {
      enabled                = true
      days                   = 7
      allow_permanent_delete = false
    }
    container_delete_retention_policy = {
      enabled = true
      days    = 7
    }
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitblob002/blobServices/default"
    error_message = "id output must be the fully-qualified ARM singleton path."
  }
}

# ── Versioning and change feed ─────────────────────────────────────────────────

run "plan_versioning_change_feed" {
  command = plan

  module {
    source = "./modules/azure/storage_account_blob_service"
  }

  variables {
    subscription_id               = "00000000-0000-0000-0000-000000000000"
    resource_group_name           = "rg-unit-test"
    account_name                  = "stunitblob003"
    is_versioning_enabled         = true
    change_feed_enabled           = true
    change_feed_retention_in_days = 30
    delete_retention_policy = {
      enabled                = true
      days                   = 7
      allow_permanent_delete = false
    }
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitblob003/blobServices/default"
    error_message = "id output must be the fully-qualified ARM singleton path."
  }
}

# ── Full configuration ─────────────────────────────────────────────────────────

run "plan_full" {
  command = plan

  module {
    source = "./modules/azure/storage_account_blob_service"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitblob004"

    cors_rules = [
      {
        allowed_origins    = ["https://app.contoso.com"]
        allowed_methods    = ["GET", "PUT", "DELETE"]
        allowed_headers    = ["*"]
        exposed_headers    = ["x-ms-request-id"]
        max_age_in_seconds = 3600
      }
    ]

    delete_retention_policy = {
      enabled                = true
      days                   = 14
      allow_permanent_delete = false
    }

    container_delete_retention_policy = {
      enabled = true
      days    = 14
    }

    is_versioning_enabled         = true
    change_feed_enabled           = true
    change_feed_retention_in_days = 30

    restore_policy_enabled = true
    restore_policy_days    = 7

    last_access_time_tracking_enabled        = true
    last_access_tracking_granularity_in_days = 1

    automatic_snapshot_policy_enabled = false
    default_service_version           = "2020-06-12"
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitblob004/blobServices/default"
    error_message = "id output must be the fully-qualified ARM singleton path."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version output must return the pinned API version."
  }
}
