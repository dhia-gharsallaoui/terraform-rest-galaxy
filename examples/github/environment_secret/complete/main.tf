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

# Call the root module with two environment-scoped secrets — one for
# staging and one for production — to show how multiple map entries share
# the same module definition.
module "root" {
  source = "../../../../"

  github_token = var.github_token

  github_environment_secrets = {
    staging_api_key = {
      owner            = var.owner
      repo             = var.repo
      environment_name = "staging"
      secret_name      = "API_KEY"
      plaintext_value  = var.staging_api_key
    }
    production_api_key = {
      owner            = var.owner
      repo             = var.repo
      environment_name = "production"
      secret_name      = "API_KEY"
      plaintext_value  = var.production_api_key
    }
  }
}
