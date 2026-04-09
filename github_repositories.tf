# ── GitHub Repositories ───────────────────────────────────────────────────────

variable "github_repositories" {
  type = map(object({
    organization           = string
    name                   = string
    check_existance        = optional(bool, false)
    description            = optional(string, null)
    homepage               = optional(string, null)
    visibility             = optional(string, "private")
    auto_init              = optional(bool, false)
    gitignore_template     = optional(string, null)
    license_template       = optional(string, null)
    has_issues             = optional(bool, null)
    has_projects           = optional(bool, null)
    has_wiki               = optional(bool, null)
    has_downloads          = optional(bool, null)
    delete_branch_on_merge = optional(bool, null)
    allow_squash_merge     = optional(bool, null)
    allow_merge_commit     = optional(bool, null)
    allow_rebase_merge     = optional(bool, null)
    allow_auto_merge       = optional(bool, null)
  }))
  description = <<-EOT
    Map of GitHub repositories to create via the GitHub REST API under an
    existing organization.

    Requires var.github_token with repo + admin:org scope.

    Example:
      github_repositories = {
        acme_demo_app = {
          organization = "my-org"
          name         = "acme-demo-app"
          description  = "Demo app managed by terraform-rest-galaxy"
          visibility   = "private"
          auto_init    = true
        }
      }
  EOT
  default     = {}
}

locals {
  github_repositories = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.github_repositories, {}), var.github_repositories)
  )
  _ghrepo_ctx = provider::rest::merge_with_outputs(local.github_repositories, module.github_repositories)
}

module "github_repositories" {
  source   = "./modules/github/repository"
  for_each = local.github_repositories

  providers = {
    rest = rest.github
  }

  depends_on = [module.azure_user_assigned_identities]

  organization           = each.value.organization
  name                   = each.value.name
  check_existance        = try(each.value.check_existance, false)
  description            = try(each.value.description, null)
  homepage               = try(each.value.homepage, null)
  visibility             = try(each.value.visibility, "private")
  auto_init              = try(each.value.auto_init, false)
  gitignore_template     = try(each.value.gitignore_template, null)
  license_template       = try(each.value.license_template, null)
  has_issues             = try(each.value.has_issues, null)
  has_projects           = try(each.value.has_projects, null)
  has_wiki               = try(each.value.has_wiki, null)
  has_downloads          = try(each.value.has_downloads, null)
  delete_branch_on_merge = try(each.value.delete_branch_on_merge, null)
  allow_squash_merge     = try(each.value.allow_squash_merge, null)
  allow_merge_commit     = try(each.value.allow_merge_commit, null)
  allow_rebase_merge     = try(each.value.allow_rebase_merge, null)
  allow_auto_merge       = try(each.value.allow_auto_merge, null)
}
