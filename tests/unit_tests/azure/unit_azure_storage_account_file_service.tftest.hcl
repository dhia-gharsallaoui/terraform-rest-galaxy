# Unit test — modules/azure/storage_account_file_service
# Plan-only: validates the singleton ARM path output known at plan time.
# Run: terraform test -filter=tests/unit_azure_storage_account_file_service.tftest.hcl

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
    source = "./modules/azure/storage_account_file_service"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitfile001"
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitfile001/fileServices/default"
    error_message = "id output must be the fully-qualified ARM singleton path."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version output must return the pinned API version."
  }
}

# ── Share soft delete ──────────────────────────────────────────────────────────

run "plan_share_soft_delete" {
  command = plan

  module {
    source = "./modules/azure/storage_account_file_service"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitfile002"
    share_delete_retention_policy = {
      enabled = true
      days    = 7
    }
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitfile002/fileServices/default"
    error_message = "id output must be the fully-qualified ARM singleton path."
  }
}

# ── SMB hardening ──────────────────────────────────────────────────────────────

run "plan_smb_hardened" {
  command = plan

  module {
    source = "./modules/azure/storage_account_file_service"
  }

  variables {
    subscription_id                = "00000000-0000-0000-0000-000000000000"
    resource_group_name            = "rg-unit-test"
    account_name                   = "stunitfile003"
    smb_versions                   = ["SMB3.0", "SMB3.1.1"]
    smb_authentication_methods     = ["Kerberos"]
    smb_kerberos_ticket_encryption = ["AES-256"]
    smb_channel_encryption         = ["AES-128-GCM", "AES-256-GCM"]
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitfile003/fileServices/default"
    error_message = "id output must be the fully-qualified ARM singleton path."
  }
}

# ── Full configuration ─────────────────────────────────────────────────────────

run "plan_full" {
  command = plan

  module {
    source = "./modules/azure/storage_account_file_service"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitfile004"

    cors_rules = [
      {
        allowed_origins    = ["https://app.contoso.com"]
        allowed_methods    = ["GET", "HEAD", "OPTIONS"]
        allowed_headers    = ["*"]
        exposed_headers    = ["x-ms-request-id"]
        max_age_in_seconds = 3600
      }
    ]

    share_delete_retention_policy = {
      enabled = true
      days    = 7
    }

    smb_versions                   = ["SMB3.0", "SMB3.1.1"]
    smb_authentication_methods     = ["Kerberos"]
    smb_kerberos_ticket_encryption = ["AES-256"]
    smb_channel_encryption         = ["AES-128-GCM", "AES-256-GCM"]
    smb_multichannel_enabled       = false
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitfile004/fileServices/default"
    error_message = "id output must be the fully-qualified ARM singleton path."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version output must return the pinned API version."
  }
}
