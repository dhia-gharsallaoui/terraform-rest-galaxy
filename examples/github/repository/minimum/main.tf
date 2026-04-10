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

# Call the root module with a single repository.
module "root" {
  source = "../../../../"

  github_token = var.github_token

  github_repositories = {
    minimum = {
      organization = var.organization
      name         = var.repository_name
    }
  }
}
