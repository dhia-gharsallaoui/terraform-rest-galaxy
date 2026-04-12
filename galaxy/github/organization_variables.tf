# ── GitHub Organization-Scoped Action Variables ───────────────────────────────

variable "github_organization_variables" {
  type = map(object({
    organization            = string
    name                    = string
    value                   = string
    visibility              = string
    selected_repository_ids = optional(list(number), null)
  }))
  description = <<-EOT
    Map of GitHub Actions variables scoped to an entire organization. Shared
    across all repositories selected by var.visibility.

    Requires var.github_token with admin:org scope.

    Example:
      github_organization_variables = {
        default_region = {
          organization = "my-org"
          name         = "DEFAULT_REGION"
          value        = "us-east-1"
          visibility   = "all"
        }
      }
  EOT
  default     = {}
}

locals {
  github_organization_variables = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.github_organization_variables, {}), var.github_organization_variables)
  )
  _ghorgvar_ctx = provider::rest::merge_with_outputs(local.github_organization_variables, module.github_organization_variables)
}

module "github_organization_variables" {
  source   = "./modules/github/organization_variable"
  for_each = local.github_organization_variables

  providers = {
    rest = rest.github
  }

  depends_on = [module.azure_user_assigned_identities]

  organization            = each.value.organization
  name                    = each.value.name
  value                   = each.value.value
  visibility              = each.value.visibility
  selected_repository_ids = try(each.value.selected_repository_ids, null)
}
