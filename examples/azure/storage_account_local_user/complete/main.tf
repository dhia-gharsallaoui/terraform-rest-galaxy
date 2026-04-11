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

# Call the root module — all vars, demonstrating full surface area.
module "root" {
  source = "../../../../"

  azure_storage_account_local_users = {
    complete = {
      subscription_id     = var.subscription_id
      resource_group_name = var.resource_group_name
      account_name        = var.account_name
      username            = var.username
      permission_scopes = [
        {
          service       = "blob"
          resource_name = "uploads"
          permissions   = "rwdlc"
        },
        {
          service       = "file"
          resource_name = "fileshare1"
          permissions   = "rwdl"
        }
      ]
      home_directory          = "uploads/home"
      allow_acl_authorization = false
      ssh_authorized_keys = var.ssh_public_key != null ? [
        {
          description = "primary-key"
          key         = var.ssh_public_key
        }
      ] : null
    }
  }
}
