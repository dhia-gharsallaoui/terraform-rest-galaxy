terraform {
  required_providers {
    rest = {
      source  = "LaurentLesle/rest"
      version = "~> 1.0"
    }
  }
}

# ── Default ARM provider (required by root module even for github-only examples) ────

provider "rest" {
  base_url = "https://management.azure.com"
  security = {
    http = {
      token = {
        token = var.access_token
      }
    }
  }
}

# Call the root module with a single organization-scoped secret visible
# to all repositories in the org.
# NOTE: the module fetches the organization's public key during plan, so
# the github_token variable must be set to a valid token with admin:org scope.
module "root" {
  source = "../../../../"

  github_token = var.github_token

  github_organization_secrets = {
    minimum = {
      organization    = var.organization
      secret_name     = var.secret_name
      plaintext_value = var.plaintext_value
      visibility      = "all"
    }
  }
}
