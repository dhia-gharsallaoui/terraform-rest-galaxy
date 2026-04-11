terraform {
  required_providers {
    rest = {
      source  = "LaurentLesle/rest"
      version = "~> 1.0"
    }
  }
}

# Step 1 — Exchange the GitHub Actions OIDC JWT for an Azure access token
provider "rest" {
  base_url = "https://login.microsoftonline.com"
  alias    = "access_token"
}

resource "rest_operation" "access_token" {
  count  = var.access_token == null ? 1 : 0
  path   = "/${var.tenant_id != null ? var.tenant_id : ""}/oauth2/v2.0/token"
  method = "POST"
  header = {
    Accept       = "application/json"
    Content-Type = "application/x-www-form-urlencoded"
  }
  body = {
    client_assertion      = var.id_token
    client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    client_id             = var.client_id
    grant_type            = "client_credentials"
    scope                 = "https://management.azure.com/.default"
  }
  provider = rest.access_token
}

locals {
  azure_token = coalesce(
    var.access_token,
    try(rest_operation.access_token[0].output["access_token"], "")
  )
}

provider "rest" {
  base_url = "https://management.azure.com"
  security = {
    http = {
      token = {
        token = local.azure_token
      }
    }
  }
}

# Complete example — multiple rules demonstrating:
#   - Blob inventory (Weekly + Daily) with Parquet and CSV formats
#   - Container inventory (Weekly) with CSV format
#   - Prefix filtering, snapshot inclusion, soft-delete inclusion
module "root" {
  source = "../../../../"

  azure_storage_account_inventory_policies = {
    complete = {
      subscription_id     = var.subscription_id
      resource_group_name = var.resource_group_name
      account_name        = var.account_name
      rules = [
        {
          name                  = "weekly-blob-parquet"
          enabled               = true
          destination           = "inventory-reports"
          schedule              = "Weekly"
          object_type           = "Blob"
          format                = "Parquet"
          schema_fields         = ["Name", "Creation-Time", "Last-Modified", "Content-Length", "BlobType", "AccessTier", "Snapshot", "VersionId", "IsCurrentVersion"]
          include_snapshots     = true
          include_blob_versions = true
          include_deleted       = false
          blob_types            = ["blockBlob", "appendBlob"]
          prefix_match          = ["data/2024/", "data/2025/"]
        },
        {
          name          = "daily-blob-csv"
          enabled       = true
          destination   = "inventory-reports"
          schedule      = "Daily"
          object_type   = "Blob"
          format        = "Csv"
          schema_fields = ["Name", "Last-Modified", "BlobType", "AccessTier"]
          blob_types    = ["blockBlob"]
        },
        {
          name          = "weekly-container-inventory"
          enabled       = true
          destination   = "inventory-reports"
          schedule      = "Weekly"
          object_type   = "Container"
          format        = "Csv"
          schema_fields = ["Name", "Last-Modified", "PublicAccess", "LeaseStatus", "HasImmutabilityPolicy"]
        }
      ]
    }
  }
}
