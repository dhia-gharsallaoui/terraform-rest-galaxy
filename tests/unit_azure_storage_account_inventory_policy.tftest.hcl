# Unit test — modules/azure/storage_account_inventory_policy
# Tests the sub-module in isolation (plan only). No real credentials needed.
# Run: terraform test -filter=tests/unit_azure_storage_account_inventory_policy.tftest.hcl

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

run "plan_inventory_policy_minimum" {
  command = plan

  module {
    source = "./modules/azure/storage_account_inventory_policy"
  }

  variables {
    subscription_id     = var.subscription_id
    resource_group_name = "rg-test"
    account_name        = "mydatalake001"
    rules = [
      {
        name          = "weekly-blob-inventory"
        destination   = "inventory-reports"
        schedule      = "Weekly"
        object_type   = "Blob"
        format        = "Parquet"
        schema_fields = ["Name", "Creation-Time", "Content-Length", "BlobType"]
      }
    ]
  }

  assert {
    condition     = output.id == "/subscriptions/${var.subscription_id}/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/mydatalake001/inventoryPolicies/default"
    error_message = "ARM ID must always end with 'inventoryPolicies/default' (singleton)."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version output must be 2025-08-01."
  }
}

run "plan_inventory_policy_complete" {
  command = plan

  module {
    source = "./modules/azure/storage_account_inventory_policy"
  }

  variables {
    subscription_id     = var.subscription_id
    resource_group_name = "rg-test"
    account_name        = "mydatalake001"
    rules = [
      {
        name                  = "weekly-blob-parquet"
        enabled               = true
        destination           = "inventory-reports"
        schedule              = "Weekly"
        object_type           = "Blob"
        format                = "Parquet"
        schema_fields         = ["Name", "Creation-Time", "Content-Length", "BlobType", "AccessTier", "Snapshot", "VersionId", "IsCurrentVersion"]
        include_snapshots     = true
        include_blob_versions = true
        blob_types            = ["blockBlob", "appendBlob"]
        prefix_match          = ["data/"]
      },
      {
        name          = "weekly-container-csv"
        destination   = "inventory-reports"
        schedule      = "Weekly"
        object_type   = "Container"
        format        = "Csv"
        schema_fields = ["Name", "Last-Modified", "PublicAccess"]
      }
    ]
  }

  assert {
    condition     = output.id == "/subscriptions/${var.subscription_id}/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/mydatalake001/inventoryPolicies/default"
    error_message = "ARM ID must always end with 'inventoryPolicies/default'."
  }
}
