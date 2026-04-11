# Unit test — modules/azure/storage_account_container
# Plan-only: validates plan-time-known outputs (id, name).

provider "rest" {
  base_url = "https://management.azure.com"
  security = {
    http = {
      token = {
        token = "placeholder-for-unit-tests"
      }
    }
  }
}

# ── Minimum ────────────────────────────────────────────────────────────────────

run "plan_minimum" {
  command = plan

  module {
    source = "./modules/azure/storage_account_container"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitcont001"
    container_name      = "mycontainer"
  }

  assert {
    condition     = output.name == "mycontainer"
    error_message = "name must echo container_name."
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitcont001/blobServices/default/containers/mycontainer"
    error_message = "id must be the fully-qualified ARM resource ID."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version must return the pinned API version."
  }
}

# ── With metadata and encryption scope ────────────────────────────────────────

run "plan_with_metadata" {
  command = plan

  module {
    source = "./modules/azure/storage_account_container"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitcont001"
    container_name      = "mycontainer-meta"
    public_access       = "None"
    metadata = {
      environment = "test"
      team        = "platform"
    }
    default_encryption_scope       = "my-scope"
    deny_encryption_scope_override = true
  }

  assert {
    condition     = output.name == "mycontainer-meta"
    error_message = "name must echo container_name."
  }
}

# ── NFS v3 squash settings ─────────────────────────────────────────────────────

run "plan_nfs_squash" {
  command = plan

  module {
    source = "./modules/azure/storage_account_container"
  }

  variables {
    subscription_id           = "00000000-0000-0000-0000-000000000000"
    resource_group_name       = "rg-unit-test"
    account_name              = "stunitnfs001"
    container_name            = "nfscontainer"
    enable_nfs_v3_root_squash = true
    enable_nfs_v3_all_squash  = false
  }

  assert {
    condition     = output.name == "nfscontainer"
    error_message = "name must echo container_name."
  }
}
