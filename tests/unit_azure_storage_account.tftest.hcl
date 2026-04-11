# Unit test — modules/azure/storage_account
# Plan-only: validates computed outputs that are known at plan time (id, name, location, kind, sku_name).
# Does NOT test API-sourced outputs (provisioning_state, endpoints) as those are only known after apply.
# NOTE: This module has a provider_check data source for Microsoft.Storage and a
# check_name_availability operation, so plan will fail with a placeholder token.
# The test is kept for structure completeness — run with real credentials to validate assertions.
# Run: TF_VAR_access_token=$(az account get-access-token ...) terraform test -filter=tests/unit_azure_storage_account.tftest.hcl

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

# ── Minimum fields ─────────────────────────────────────────────────────────────

run "plan_minimum" {
  command = plan

  module {
    source = "./modules/azure/storage_account"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitmin001"
    sku_name            = "Standard_LRS"
    kind                = "StorageV2"
    location            = "westeurope"
  }

  assert {
    condition     = output.name == "stunitmin001"
    error_message = "name output must echo account_name."
  }

  assert {
    condition     = output.location == "westeurope"
    error_message = "location output must echo location."
  }

  assert {
    condition     = output.kind == "StorageV2"
    error_message = "kind output must echo kind."
  }

  assert {
    condition     = output.sku_name == "Standard_LRS"
    error_message = "sku_name output must echo sku_name."
  }

  assert {
    condition     = output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Storage/storageAccounts/stunitmin001"
    error_message = "id output must be the fully-qualified ARM resource ID."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version output must return the pinned API version."
  }
}

# ── ADLS Gen2 / NFS configuration ─────────────────────────────────────────────

run "plan_adls_nfs" {
  command = plan

  module {
    source = "./modules/azure/storage_account"
  }

  variables {
    subscription_id        = "00000000-0000-0000-0000-000000000000"
    resource_group_name    = "rg-unit-test"
    account_name           = "stunitnfs001"
    sku_name               = "Standard_LRS"
    kind                   = "StorageV2"
    location               = "westeurope"
    is_hns_enabled         = true
    is_nfs_v3_enabled      = true
    is_local_user_enabled  = true
    is_sftp_enabled        = true
    enable_extended_groups = true
  }

  assert {
    condition     = output.name == "stunitnfs001"
    error_message = "name must echo account_name."
  }
}

# ── System-assigned identity ───────────────────────────────────────────────────

run "plan_system_identity" {
  command = plan

  module {
    source = "./modules/azure/storage_account"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitid001"
    sku_name            = "Standard_LRS"
    kind                = "StorageV2"
    location            = "westeurope"
    identity_type       = "SystemAssigned"
  }

  assert {
    condition     = output.name == "stunitid001"
    error_message = "name must echo account_name."
  }
}

# ── Network ACLs ──────────────────────────────────────────────────────────────

run "plan_network_acls" {
  command = plan

  module {
    source = "./modules/azure/storage_account"
  }

  variables {
    subscription_id       = "00000000-0000-0000-0000-000000000000"
    resource_group_name   = "rg-unit-test"
    account_name          = "stunitnet001"
    sku_name              = "Standard_LRS"
    kind                  = "StorageV2"
    location              = "westeurope"
    public_network_access = "Disabled"
    network_acls = {
      default_action             = "Deny"
      bypass                     = ["AzureServices"]
      ip_rules                   = ["203.0.113.0/24"]
      virtual_network_subnet_ids = []
    }
  }

  assert {
    condition     = output.name == "stunitnet001"
    error_message = "name must echo account_name."
  }
}

# ── SAS policy + key expiration ────────────────────────────────────────────────

run "plan_sas_and_key_policy" {
  command = plan

  module {
    source = "./modules/azure/storage_account"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitpol001"
    sku_name            = "Standard_LRS"
    kind                = "StorageV2"
    location            = "westeurope"
    sas_policy = {
      sas_expiration_period = "7.00:00:00"
      expiration_action     = "Log"
    }
    key_expiration_period_in_days = 90
  }

  assert {
    condition     = output.name == "stunitpol001"
    error_message = "name must echo account_name."
  }
}

# ── Large file shares ─────────────────────────────────────────────────────────

run "plan_large_file_shares" {
  command = plan

  module {
    source = "./modules/azure/storage_account"
  }

  variables {
    subscription_id         = "00000000-0000-0000-0000-000000000000"
    resource_group_name     = "rg-unit-test"
    account_name            = "stunitlfs001"
    sku_name                = "Standard_LRS"
    kind                    = "StorageV2"
    location                = "westeurope"
    large_file_shares_state = "Enabled"
  }

  assert {
    condition     = output.name == "stunitlfs001"
    error_message = "name must echo account_name."
  }
}

# ── Routing preference ────────────────────────────────────────────────────────

run "plan_routing_preference" {
  command = plan

  module {
    source = "./modules/azure/storage_account"
  }

  variables {
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    resource_group_name = "rg-unit-test"
    account_name        = "stunitrout001"
    sku_name            = "Standard_LRS"
    kind                = "StorageV2"
    location            = "westeurope"
    routing_preference = {
      routing_choice              = "MicrosoftRouting"
      publish_microsoft_endpoints = true
      publish_internet_endpoints  = false
    }
  }

  assert {
    condition     = output.name == "stunitrout001"
    error_message = "name must echo account_name."
  }
}
