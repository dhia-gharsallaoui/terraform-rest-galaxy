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

# Call the root module with an organization-scoped secret restricted to a
# specific list of repositories via visibility = "selected". This shows
# how to use selected_repository_ids with numeric repository IDs.
module "root" {
  source = "../../../../"

  github_token = var.github_token

  github_organization_secrets = {
    complete = {
      organization            = var.organization
      secret_name             = var.secret_name
      plaintext_value         = var.plaintext_value
      visibility              = "selected"
      selected_repository_ids = var.selected_repository_ids
    }
  }
}
