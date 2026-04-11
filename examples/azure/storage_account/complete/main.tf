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

# Call the root module — all vars, passed as a single-entry map.
module "root" {
  source = "../../../../"

  azure_storage_accounts = {
    complete = {
      subscription_id                              = var.subscription_id
      resource_group_name                          = var.resource_group_name
      account_name                                 = var.account_name
      sku_name                                     = var.sku_name
      kind                                         = var.kind
      location                                     = var.location
      tags                                         = var.tags
      zones                                        = var.zones
      identity_type                                = var.identity_type
      identity_user_assigned_identity_ids          = var.identity_user_assigned_identity_ids
      access_tier                                  = var.access_tier
      https_traffic_only_enabled                   = var.https_traffic_only_enabled
      minimum_tls_version                          = var.minimum_tls_version
      allow_blob_public_access                     = var.allow_blob_public_access
      allow_shared_key_access                      = var.allow_shared_key_access
      is_hns_enabled                               = var.is_hns_enabled
      public_network_access                        = var.public_network_access
      default_to_oauth_authentication              = var.default_to_oauth_authentication
      allow_cross_tenant_replication               = var.allow_cross_tenant_replication
      large_file_shares_state                      = var.large_file_shares_state
      routing_preference                           = var.routing_preference
      sas_policy                                   = var.sas_policy
      key_expiration_period_in_days                = var.key_expiration_period_in_days
      dns_endpoint_type                            = var.dns_endpoint_type
      is_sftp_enabled                              = var.is_sftp_enabled
      is_local_user_enabled                        = var.is_local_user_enabled
      is_nfs_v3_enabled                            = var.is_nfs_v3_enabled
      enable_extended_groups                       = var.enable_extended_groups
      immutable_storage_with_versioning_enabled    = var.immutable_storage_with_versioning_enabled
      network_acls                                 = var.network_acls
      encryption_key_source                        = var.encryption_key_source
      encryption_key_vault_uri                     = var.encryption_key_vault_uri
      encryption_key_name                          = var.encryption_key_name
      encryption_key_version                       = var.encryption_key_version
      encryption_identity                          = var.encryption_identity
      encryption_require_infrastructure_encryption = var.encryption_require_infrastructure_encryption
    }
  }
}
