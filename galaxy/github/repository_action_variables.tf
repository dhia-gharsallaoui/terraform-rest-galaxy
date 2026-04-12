# ── GitHub Repository Action Variables ─────────────────────────────────────────

variable "github_repository_action_variables" {
  type = map(object({
    owner = string
    repo  = string
    name  = string
    value = string
  }))
  description = <<-EOT
    Map of GitHub Actions repository variables to create via the GitHub REST API.
    These are plain-text variables (not secrets) accessible in workflows via
    ${"$"}{{ vars.NAME }}.

    Requires var.github_token with repo scope.

    Example:
      github_repository_action_variables = {
        azure_client_id = {
          owner = "my-org"
          repo  = "my-repo"
          name  = "AZURE_CLIENT_ID"
          value = "00000000-0000-0000-0000-000000000000"
        }
      }
  EOT
  default     = {}
}

locals {
  github_repository_action_variables = provider::rest::resolve_map(
    local._ctx_l4,
    merge(try(local._yaml_raw.github_repository_action_variables, {}), var.github_repository_action_variables)
  )
}

module "github_repository_action_variables" {
  source   = "./modules/github/repository_action_variable"
  for_each = local.github_repository_action_variables

  providers = {
    rest = rest.github
  }

  # Repo variables require the repository to exist before POST, so we
  # depend on github_repositories in addition to the baseline.
  depends_on = [
    module.azure_user_assigned_identities,
    module.github_repositories,
  ]

  owner = each.value.owner
  repo  = each.value.repo
  name  = each.value.name
  value = each.value.value
}
