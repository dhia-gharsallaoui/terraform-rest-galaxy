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

  azure_storage_account_object_replication_policies = {
    complete = {
      subscription_id              = var.subscription_id
      resource_group_name          = var.resource_group_name
      account_name                 = var.account_name
      source_account               = var.source_account
      policy_id                    = "default"
      metrics_enabled              = true
      priority_replication_enabled = false
      tags_replication_enabled     = true
      rules = [
        {
          source_container      = "raw-data"
          destination_container = "replicated-raw"
          min_creation_time     = "2024-01-01T00:00:00Z"
          prefix_match          = ["prefix/2024/", "prefix/2025/"]
        },
        {
          source_container      = "processed-data"
          destination_container = "replicated-processed"
        }
      ]
    }
  }
}
