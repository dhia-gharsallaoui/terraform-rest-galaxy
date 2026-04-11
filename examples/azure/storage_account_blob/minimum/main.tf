terraform {
  required_providers {
    rest = {
      source  = "LaurentLesle/rest"
      version = "~> 1.0"
    }
  }
}

# ── Step 1 — Exchange the GitHub Actions OIDC JWT for a storage.azure.com token
# var.id_token is set via TF_VAR_id_token=$ACTIONS_ID_TOKEN_REQUEST_TOKEN in CI.
# The scope must be https://storage.azure.com/.default (NOT management.azure.com).
provider "rest" {
  base_url = "https://login.microsoftonline.com"
  alias    = "oidc_token"
}

resource "rest_operation" "storage_access_token" {
  count  = var.storage_access_token == null ? 1 : 0
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
    scope                 = "https://storage.azure.com/.default"
  }
  provider = rest.oidc_token
}

locals {
  # Direct token (local dev) takes precedence over OIDC-exchanged token (CI).
  storage_token = coalesce(
    var.storage_access_token,
    try(rest_operation.storage_access_token[0].output["access_token"], "")
  )
}

# ── Main provider — Blob Storage data-plane endpoint ─────────────────────────
# NOTE: base_url encodes the storage account name. For blobs in multiple
# storage accounts, use separate provider aliases.
provider "rest" {
  base_url = "https://${var.account_name}.blob.core.windows.net"
  security = {
    http = {
      token = {
        token = local.storage_token
      }
    }
  }
}

# ── Root module — minimum required variables only ────────────────────────────
module "root" {
  source = "../../../../"

  azure_storage_account_blobs = {
    minimum = {
      account_name   = var.account_name
      container_name = var.container_name
      blob_name      = var.blob_name
    }
  }

  # Pass the storage.azure.com token for the blob provider alias
  storage_access_token = local.storage_token
  storage_account_name = var.account_name
}
