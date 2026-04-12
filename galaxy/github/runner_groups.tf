# ── GitHub Runner Groups ──────────────────────────────────────────────────────

variable "github_runner_groups" {
  type = map(object({
    organization               = string
    name                       = string
    visibility                 = optional(string, "all")
    allows_public_repositories = optional(bool, false)
    restricted_to_workflows    = optional(bool, false)
    selected_workflows         = optional(list(string), null)
    network_configuration_id   = optional(string, null)
  }))
  description = <<-EOT
    Map of GitHub Actions runner groups to create via the GitHub REST API.
    Each runner group can optionally reference a GitHub.Network/networkSettings
    resource for VNet injection.

    Requires var.github_token with admin:org scope.

    Example:
      github_runner_groups = {
        azure_runners = {
          organization             = "my-org"
          name                     = "azure-vnet-runners"
          visibility               = "all"
          network_configuration_id = "ref:azure_github_network_settings.runners.id"
        }
      }
  EOT
  default     = {}
}

locals {
  github_runner_groups = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.github_runner_groups, {}), var.github_runner_groups)
  )
  _ghrg_ctx = provider::rest::merge_with_outputs(local.github_runner_groups, module.github_runner_groups)
}

module "github_runner_groups" {
  source   = "./modules/github/runner_group"
  for_each = local.github_runner_groups

  providers = {
    rest = rest.github
  }

  depends_on = [module.azure_github_network_settings]

  organization               = each.value.organization
  name                       = each.value.name
  visibility                 = try(each.value.visibility, "all")
  allows_public_repositories = try(each.value.allows_public_repositories, false)
  restricted_to_workflows    = try(each.value.restricted_to_workflows, false)
  selected_workflows         = try(each.value.selected_workflows, null)
  network_configuration_id   = try(each.value.network_configuration_id, null)
}
