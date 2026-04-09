# ── GitHub Deployment Environments ────────────────────────────────────────────

variable "github_environments" {
  type = map(object({
    owner               = string
    repo                = string
    name                = string
    wait_timer          = optional(number, null)
    prevent_self_review = optional(bool, null)
    reviewers = optional(list(object({
      type = string
      id   = number
    })), null)
    deployment_branch_policy = optional(object({
      protected_branches     = bool
      custom_branch_policies = bool
    }), null)
  }))
  description = <<-EOT
    Map of GitHub deployment environments to create via the GitHub REST API.
    Each environment is created with PUT /repos/{owner}/{repo}/environments/{name}
    which is idempotent. Optional wait_timer, reviewers, and
    deployment_branch_policy control job protection rules.

    Requires var.github_token with repo scope.

    Example:
      github_environments = {
        acme_demo_production = {
          owner      = "my-org"
          repo       = "acme-demo-app"
          name       = "production"
          wait_timer = 5
          reviewers  = [{ type = "Team", id = 12345 }]
        }
      }
  EOT
  default     = {}
}

locals {
  github_environments = provider::rest::resolve_map(
    local._ctx_l4,
    merge(try(local._yaml_raw.github_environments, {}), var.github_environments)
  )
  _ghenv_ctx = provider::rest::merge_with_outputs(local.github_environments, module.github_environments)
}

module "github_environments" {
  source   = "./modules/github/environment"
  for_each = local.github_environments

  providers = {
    rest = rest.github
  }

  depends_on = [module.github_repositories]

  owner                    = each.value.owner
  repo                     = each.value.repo
  name                     = each.value.name
  wait_timer               = try(each.value.wait_timer, null)
  prevent_self_review      = try(each.value.prevent_self_review, null)
  reviewers                = try(each.value.reviewers, null)
  deployment_branch_policy = try(each.value.deployment_branch_policy, null)
}
