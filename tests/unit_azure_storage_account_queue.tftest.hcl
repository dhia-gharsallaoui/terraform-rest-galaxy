# Unit test — modules/azure/storage_account_queue
# Tests the sub-module in isolation (plan only).
# Run: terraform test -filter=tests/unit_azure_storage_account_queue.tftest.hcl

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
    source = "./modules/azure/storage_account_queue"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunittest001"
    queue_name          = "my-queue"
  }

  assert {
    condition     = output.name == "my-queue"
    error_message = "name must echo queue_name."
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunittest001/queueServices/default/queues/my-queue"
    error_message = "id must be the fully-qualified ARM resource ID."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version must return the pinned API version."
  }
}

# ── With metadata ─────────────────────────────────────────────────────────────

run "plan_with_metadata" {
  command = plan

  module {
    source = "./modules/azure/storage_account_queue"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunittest001"
    queue_name          = "events-queue"
    metadata = {
      environment = "test"
      team        = "platform"
    }
  }

  assert {
    condition     = output.name == "events-queue"
    error_message = "name must echo queue_name."
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunittest001/queueServices/default/queues/events-queue"
    error_message = "id must be the fully-qualified ARM resource ID."
  }
}
