# ── GitHub Environment-Scoped Action Secrets ──────────────────────────────────

variable "github_environment_secrets" {
  type = map(object({
    owner            = string
    repo             = string
    environment_name = string
    secret_name      = string
    plaintext_value  = string
  }))
  description = <<-EOT
    Map of GitHub Actions secrets scoped to a specific deployment environment.
    Encrypted with NaCl sealed-box using the environment's public key.

    Requires var.github_token with repo scope.

    Example:
      github_environment_secrets = {
        staging_api_key = {
          owner            = "my-org"
          repo             = "acme-demo-app"
          environment_name = "staging"
          secret_name      = "API_KEY"
          plaintext_value  = "..."
        }
      }
  EOT
  default     = {}
}

locals {
  github_environment_secrets = provider::rest::resolve_map(
    local._ctx_l5,
    merge(try(local._yaml_raw.github_environment_secrets, {}), var.github_environment_secrets)
  )
}

module "github_environment_secrets" {
  source   = "./modules/github/environment_secret"
  for_each = local.github_environment_secrets

  providers = {
    rest = rest.github
  }

  # The data.rest_resource.public_key inside this module fetches the
  # environment's NaCl public key. That endpoint only returns 200 once the
  # repository AND the environment exist, so we defer the refresh until
  # after both have been applied.
  depends_on = [
    module.github_repositories,
    module.github_environments,
  ]

  owner            = each.value.owner
  repo             = each.value.repo
  environment_name = each.value.environment_name
  secret_name      = each.value.secret_name
  plaintext_value  = each.value.plaintext_value
}
