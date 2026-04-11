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

module "root" {
  source = "../../../../"

  azure_foundry_accounts = {
    complete = {
      subscription_id                     = var.subscription_id
      resource_group_name                 = var.resource_group_name
      account_name                        = var.account_name
      location                            = var.location
      sku_name                            = var.sku_name
      kind                                = var.kind
      identity_type                       = var.identity_type
      identity_user_assigned_identity_ids = var.identity_user_assigned_identity_ids
      allow_project_management            = var.allow_project_management
      public_network_access               = var.public_network_access
      custom_sub_domain_name              = var.custom_sub_domain_name
      disable_local_auth                  = var.disable_local_auth
      network_acls_default_action         = var.network_acls_default_action
      network_acls_bypass                 = var.network_acls_bypass
      tags                                = var.tags
    }
  }
}
