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

# Call the root module — all variables, showing the full surface area of the module.
module "root" {
  source = "../../../../"

  azure_storage_account_file_services = {
    complete = {
      subscription_id     = var.subscription_id
      resource_group_name = var.resource_group_name
      account_name        = var.account_name

      cors_rules = var.cors_rules

      share_delete_retention_policy = {
        enabled = true
        days    = var.share_delete_retention_days
      }

      smb_versions                   = var.smb_versions
      smb_authentication_methods     = var.smb_authentication_methods
      smb_kerberos_ticket_encryption = var.smb_kerberos_ticket_encryption
      smb_channel_encryption         = var.smb_channel_encryption
      smb_multichannel_enabled       = var.smb_multichannel_enabled

      nfs_v3_enabled   = var.nfs_v3_enabled
      nfs_v4_1_enabled = var.nfs_v4_1_enabled
    }
  }
}
