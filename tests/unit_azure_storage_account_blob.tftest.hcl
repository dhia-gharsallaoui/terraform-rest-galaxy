# Unit test — modules/azure/storage_account_blob
# Plan-only: validates plan-time-known outputs (id, name, container_name, account_name, blob_url, api_version).
# Does NOT test API-sourced outputs (etag, last_modified, version_id) as those are only known after apply.
#
# Run: terraform test -filter=tests/unit_azure_storage_account_blob.tftest.hcl
#
# NOTE: The provider base_url is set to the blob storage data-plane endpoint.
# A storage.azure.com-scoped token is required in production; "placeholder" is
# sufficient for plan-only tests since no real API calls are made.

provider "rest" {
  base_url = "https://testaccount.blob.core.windows.net"
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
    source = "./modules/azure/storage_account_blob"
  }

  variables {
    account_name   = "testaccount"
    container_name = "mycontainer"
    blob_name      = "path/to/blob.txt"
  }

  assert {
    condition     = output.id == "/mycontainer/path/to/blob.txt"
    error_message = "id output must be /{containerName}/{blobName}."
  }

  assert {
    condition     = output.name == "path/to/blob.txt"
    error_message = "name output must echo blob_name."
  }

  assert {
    condition     = output.container_name == "mycontainer"
    error_message = "container_name output must echo container_name."
  }

  assert {
    condition     = output.account_name == "testaccount"
    error_message = "account_name output must echo account_name."
  }

  assert {
    condition     = output.blob_url == "https://testaccount.blob.core.windows.net/mycontainer/path/to/blob.txt"
    error_message = "blob_url must be the fully-qualified HTTPS URL of the blob."
  }

  assert {
    condition     = output.api_version == "2026-06-06"
    error_message = "api_version output must return the pinned API version."
  }
}

# ── With content and content_type ─────────────────────────────────────────────

run "plan_with_content" {
  command = plan

  module {
    source = "./modules/azure/storage_account_blob"
  }

  variables {
    account_name   = "testaccount"
    container_name = "configs"
    blob_name      = "production/config.json"
    content        = "{\"env\":\"prod\"}"
    content_type   = "application/json"
    access_tier    = "Hot"
  }

  assert {
    condition     = output.id == "/configs/production/config.json"
    error_message = "id must reflect container and blob path."
  }

  assert {
    condition     = output.blob_url == "https://testaccount.blob.core.windows.net/configs/production/config.json"
    error_message = "blob_url must include container and blob path."
  }
}

# ── With metadata ─────────────────────────────────────────────────────────────

run "plan_with_metadata" {
  command = plan

  module {
    source = "./modules/azure/storage_account_blob"
  }

  variables {
    account_name   = "testaccount"
    container_name = "mycontainer"
    blob_name      = "tagged.txt"
    metadata = {
      team        = "platform"
      environment = "production"
    }
  }

  assert {
    condition     = output.name == "tagged.txt"
    error_message = "name must echo blob_name."
  }
}

# ── SAS auth mode ─────────────────────────────────────────────────────────────

run "plan_sas_auth" {
  command = plan

  module {
    source = "./modules/azure/storage_account_blob"
  }

  variables {
    account_name   = "testaccount"
    container_name = "mycontainer"
    blob_name      = "sas-protected.txt"
    auth_mode      = "sas"
    sas_token      = "sv=2021-06-08&ss=b&srt=o&sp=rwd&se=2099-01-01T00:00:00Z&spr=https&sig=placeholder"
  }

  assert {
    condition     = output.id == "/mycontainer/sas-protected.txt"
    error_message = "id must be correct for SAS auth mode."
  }
}

# ── check_existance flag ──────────────────────────────────────────────────────

run "plan_check_existance" {
  command = plan

  module {
    source = "./modules/azure/storage_account_blob"
  }

  variables {
    account_name    = "testaccount"
    container_name  = "brownfield"
    blob_name       = "existing.json"
    check_existance = true
  }

  assert {
    condition     = output.id == "/brownfield/existing.json"
    error_message = "id must be correct when check_existance is true."
  }
}
