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

# Call the root module with a production environment that exercises all
# optional protection rules: wait_timer, prevent_self_review, reviewers,
# and a deployment_branch_policy that only allows protected branches.
module "root" {
  source = "../../../../"

  github_token = var.github_token

  github_environments = {
    complete = {
      owner               = var.owner
      repo                = var.repo
      name                = var.environment_name
      wait_timer          = 5
      prevent_self_review = true
      reviewers = [
        {
          type = "Team"
          id   = var.reviewer_team_id
        }
      ]
      deployment_branch_policy = {
        protected_branches     = true
        custom_branch_policies = false
      }
    }
  }
}
