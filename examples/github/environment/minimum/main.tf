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

# Call the root module with a single deployment environment.
module "root" {
  source = "../../../../"

  github_token = var.github_token

  github_environments = {
    minimum = {
      owner = var.owner
      repo  = var.repo
      name  = var.environment_name
    }
  }
}
