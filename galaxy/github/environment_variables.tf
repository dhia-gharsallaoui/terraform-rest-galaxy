# ── GitHub Environment-Scoped Action Variables ────────────────────────────────

variable "github_environment_variables" {
  type = map(object({
    owner            = string
    repo             = string
    environment_name = string
    name             = string
    value            = string
  }))
  description = <<-EOT
    Map of GitHub Actions variables scoped to a specific deployment environment.
    These are plain-text variables (not secrets) accessible in workflows via
    ${"$"}{{ vars.NAME }} when the job references the environment.

    Requires var.github_token with repo scope.

    Example:
      github_environment_variables = {
        staging_api_url = {
          owner            = "my-org"
          repo             = "acme-demo-app"
          environment_name = "staging"
          name             = "API_URL"
          value            = "https://staging.acme.example.com"
        }
      }
  EOT
  default     = {}
}

locals {
  github_environment_variables = provider::rest::resolve_map(
    local._ctx_l5,
    merge(try(local._yaml_raw.github_environment_variables, {}), var.github_environment_variables)
  )
}

module "github_environment_variables" {
  source   = "./modules/github/environment_variable"
  for_each = local.github_environment_variables

  providers = {
    rest = rest.github
  }

  # Variables don't fetch a public key, but the POST endpoint still requires
  # the environment to exist first, so we depend on both repositories and
  # environments (environments implicitly depend on repositories).
  depends_on = [
    module.github_repositories,
    module.github_environments,
  ]

  owner            = each.value.owner
  repo             = each.value.repo
  environment_name = each.value.environment_name
  name             = each.value.name
  value            = each.value.value
}
