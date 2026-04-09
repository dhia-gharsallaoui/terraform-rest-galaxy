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

# Call the root module with a single repository using every optional field.
module "root" {
  source = "../../../../"

  github_token = var.github_token

  github_repositories = {
    complete = {
      organization           = var.organization
      name                   = var.repository_name
      description            = "Repository created by terraform-rest-galaxy integration test"
      homepage               = "https://example.com"
      visibility             = "private"
      auto_init              = true
      gitignore_template     = "Terraform"
      license_template       = "mit"
      has_issues             = true
      has_projects           = false
      has_wiki               = false
      has_downloads          = true
      delete_branch_on_merge = true
      allow_squash_merge     = true
      allow_merge_commit     = false
      allow_rebase_merge     = true
      allow_auto_merge       = false
    }
  }
}
