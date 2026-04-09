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

# Call the root module with a single environment-scoped secret.
# NOTE: the module fetches the environment's public key during plan, so
# the github_token variable must be set to a valid token with repo scope
# for `terraform plan` to succeed.
module "root" {
  source = "../../../../"

  github_token = var.github_token

  github_environment_secrets = {
    minimum = {
      owner            = var.owner
      repo             = var.repo
      environment_name = var.environment_name
      secret_name      = var.secret_name
      plaintext_value  = var.plaintext_value
    }
  }
}
