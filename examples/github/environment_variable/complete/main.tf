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

# Call the root module with two environment-scoped variables — the same
# logical variable (API_URL) with different values for staging and production.
module "root" {
  source = "../../../../"

  github_token = var.github_token

  github_environment_variables = {
    staging_api_url = {
      owner            = var.owner
      repo             = var.repo
      environment_name = "staging"
      name             = "API_URL"
      value            = "https://staging.example.com"
    }
    production_api_url = {
      owner            = var.owner
      repo             = var.repo
      environment_name = "production"
      name             = "API_URL"
      value            = "https://api.example.com"
    }
  }
}
