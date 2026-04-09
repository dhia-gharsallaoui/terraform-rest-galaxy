# ── GitHub Organization-Scoped Action Secrets ─────────────────────────────────

variable "github_organization_secrets" {
  type = map(object({
    organization            = string
    secret_name             = string
    plaintext_value         = string
    visibility              = string
    selected_repository_ids = optional(list(number), null)
  }))
  description = <<-EOT
    Map of GitHub Actions secrets scoped to an entire organization. Shared
    across all repositories selected by var.visibility. Encrypted with NaCl
    sealed-box using the organization's public key.

    Requires var.github_token with admin:org scope.

    Example:
      github_organization_secrets = {
        shared_npm_token = {
          organization    = "my-org"
          secret_name     = "NPM_TOKEN"
          plaintext_value = "..."
          visibility      = "all"
        }
      }
  EOT
  default     = {}
}

locals {
  github_organization_secrets = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.github_organization_secrets, {}), var.github_organization_secrets)
  )
  _ghorgsec_ctx = provider::rest::merge_with_outputs(local.github_organization_secrets, module.github_organization_secrets)
}

module "github_organization_secrets" {
  source   = "./modules/github/organization_secret"
  for_each = local.github_organization_secrets

  providers = {
    rest = rest.github
  }

  depends_on = [module.azure_user_assigned_identities]

  organization            = each.value.organization
  secret_name             = each.value.secret_name
  plaintext_value         = each.value.plaintext_value
  visibility              = each.value.visibility
  selected_repository_ids = try(each.value.selected_repository_ids, null)
}
