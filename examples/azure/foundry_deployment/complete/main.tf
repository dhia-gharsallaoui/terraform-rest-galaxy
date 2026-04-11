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

# Complete: all optional fields — pinned version, RAI policy, capacity, spillover.
module "root" {
  source = "../../../../"

  azure_foundry_deployments = {
    complete = {
      subscription_id     = var.subscription_id
      resource_group_name = var.resource_group_name
      account_name        = var.account_name
      location            = var.location
      deployment_name     = var.deployment_name

      model_format  = "OpenAI"
      model_name    = "gpt-4o"
      model_version = "2024-08-06"

      sku_name     = "GlobalStandard"
      sku_capacity = 100

      version_upgrade_option = "OnceCurrentVersionExpired"
      rai_policy_name        = "Microsoft.Default"

      capacity_settings_designated_capacity = 100
      capacity_settings_priority            = 1

      spillover_deployment_name = "gpt-4o-fallback"

      tags = {
        environment = "production"
        model       = "gpt-4o"
      }
    }
  }
}
