terraform {
  required_providers {
    rest = {
      source  = "LaurentLesle/rest"
      version = "~> 1.0"
    }
  }
}

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

# Minimum: required fields only — model, SKU, parent account reference.
module "root" {
  source = "../../../../"

  azure_foundry_deployments = {
    minimum = {
      subscription_id     = var.subscription_id
      resource_group_name = var.resource_group_name
      account_name        = var.account_name
      location            = var.location
      deployment_name     = var.deployment_name
      model_format        = var.model_format
      model_name          = var.model_name
      sku_name            = var.sku_name
    }
  }
}
