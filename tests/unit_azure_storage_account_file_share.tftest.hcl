# Unit test — modules/azure/storage_account_file_share
# Tests the sub-module in isolation (plan only).
# Run: terraform test -filter=tests/unit_azure_storage_account_file_share.tftest.hcl

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
    source = "./modules/azure/storage_account_file_share"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunittest001"
    share_name          = "testshare"
    share_quota         = 100
  }

  assert {
    condition     = output.name == "testshare"
    error_message = "name must echo share_name."
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunittest001/fileServices/default/shares/testshare"
    error_message = "id must be the fully-qualified ARM resource ID."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version must return the pinned API version."
  }
}

# ── NFS share with root squash ────────────────────────────────────────────────

run "plan_nfs" {
  command = plan

  module {
    source = "./modules/azure/storage_account_file_share"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunfsstorage001"
    share_name          = "nfsshare"
    share_quota         = 1024
    enabled_protocols   = "NFS"
    root_squash         = "RootSquash"
  }

  assert {
    condition     = output.name == "nfsshare"
    error_message = "name must echo share_name."
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunfsstorage001/fileServices/default/shares/nfsshare"
    error_message = "id must be the fully-qualified ARM resource ID."
  }
}

# ── SMB share with metadata ───────────────────────────────────────────────────

run "plan_smb_with_metadata" {
  command = plan

  module {
    source = "./modules/azure/storage_account_file_share"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunittest001"
    share_name          = "smbshare"
    share_quota         = 512
    enabled_protocols   = "SMB"
    access_tier         = "Hot"
    metadata = {
      environment = "test"
      team        = "platform"
    }
  }

  assert {
    condition     = output.name == "smbshare"
    error_message = "name must echo share_name."
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunittest001/fileServices/default/shares/smbshare"
    error_message = "id must be the fully-qualified ARM resource ID."
  }
}
