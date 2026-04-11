terraform {
  required_providers {
    rest = {
      source  = "LaurentLesle/rest"
      version = "~> 1.0"
    }
  }
}

# Step 1 — Exchange the GitHub Actions OIDC JWT for an Azure access token
# var.id_token is set via TF_VAR_id_token=$ACTIONS_ID_TOKEN_REQUEST_TOKEN in CI
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
  # Direct token (local dev) takes precedence over OIDC-exchanged token (CI).
  azure_token = coalesce(
    var.access_token,
    try(rest_operation.access_token[0].output["access_token"], "")
  )
}

# Main provider — authenticated with the Azure access token
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

# Call the root module — complete configuration:
# Multiple rules for a data lake lifecycle: tier to cool, archive, and delete.
# Also manages snapshot and blob version lifecycle.
module "root" {
  source = "../../../../"

  azure_storage_account_management_policies = {
    complete = {
      subscription_id     = var.subscription_id
      resource_group_name = var.resource_group_name
      account_name        = var.account_name
      rules = [
        {
          name    = "tier-raw-blobs"
          enabled = true
          filters = {
            blob_types   = ["blockBlob"]
            prefix_match = ["raw/", "processed/"]
          }
          actions = {
            base_blob = {
              tier_to_cool_after_days_since_modification_greater_than    = 30
              tier_to_archive_after_days_since_modification_greater_than = 180
              delete_after_days_since_modification_greater_than          = 1825
            }
            snapshot = {
              change_tier_to_cool_after_days_since_creation    = 30
              change_tier_to_archive_after_days_since_creation = 90
              delete_after_days_since_creation_greater_than    = 365
            }
            version = {
              change_tier_to_cool_after_days_since_creation    = 30
              change_tier_to_archive_after_days_since_creation = 90
              delete_after_days_since_creation                 = 365
            }
          }
        },
        {
          name    = "delete-temp"
          enabled = true
          filters = {
            blob_types   = ["blockBlob"]
            prefix_match = ["tmp/", "scratch/"]
          }
          actions = {
            base_blob = {
              delete_after_days_since_last_access_time_greater_than = 7
            }
          }
        },
        {
          name    = "archive-append-logs"
          enabled = true
          filters = {
            blob_types = ["appendBlob"]
          }
          actions = {
            base_blob = {
              tier_to_archive_after_days_since_modification_greater_than = 90
              delete_after_days_since_modification_greater_than          = 730
            }
          }
        }
      ]
    }
  }
}
