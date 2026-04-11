# Unit test — modules/azure/storage_account_object_replication_policy
# Tests the sub-module in isolation (plan only). No real credentials needed.
# Run: terraform test -filter=tests/unit_azure_storage_account_object_replication_policy.tftest.hcl

variable "access_token" {
  type      = string
  sensitive = true
  default   = "placeholder"
}

provider "rest" {
  base_url = "https://management.azure.com"
  security = {
    http = {
      token = {
        token = var.access_token
      }
    }
  }
}

variable "subscription_id" {
  type    = string
  default = "00000000-0000-0000-0000-000000000000"
}

run "plan_object_replication_policy_default" {
  command = plan

  module {
    source = "./modules/azure/storage_account_object_replication_policy"
  }

  variables {
    subscription_id     = var.subscription_id
    resource_group_name = "rg-test"
    account_name        = "mydestination001"
    source_account      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/mysource001"
    rules = [
      {
        source_container      = "source-data"
        destination_container = "replicated-data"
      }
    ]
  }

  assert {
    condition     = output.id == "/subscriptions/${var.subscription_id}/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/mydestination001/objectReplicationPolicies/default"
    error_message = "ARM ID must be correctly formed with 'default' policy_id."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version output must be 2025-08-01."
  }
}

run "plan_object_replication_policy_with_filters" {
  command = plan

  module {
    source = "./modules/azure/storage_account_object_replication_policy"
  }

  variables {
    subscription_id          = var.subscription_id
    resource_group_name      = "rg-test"
    account_name             = "mydestination001"
    source_account           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/mysource001"
    policy_id                = "default"
    metrics_enabled          = true
    tags_replication_enabled = true
    rules = [
      {
        source_container      = "raw-data"
        destination_container = "replicated-raw"
        min_creation_time     = "2024-01-01T00:00:00Z"
        prefix_match          = ["logs/", "data/"]
      }
    ]
  }

  assert {
    condition     = output.id == "/subscriptions/${var.subscription_id}/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/mydestination001/objectReplicationPolicies/default"
    error_message = "ARM ID must be correctly formed."
  }
}
