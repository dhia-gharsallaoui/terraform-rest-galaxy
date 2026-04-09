# Source: GitHub REST API
#   api        : GitHub REST API v2022-11-28
#   resource   : repos
#   create     : POST   /orgs/{org}/repos                  (synchronous, server-assigned id)
#   read       : GET    /repos/{org}/{name}
#   update     : PATCH  /repos/{org}/{name}
#   delete     : DELETE /repos/{org}/{name}
#
# NOTE: This module requires a rest provider configured with
#   base_url = "https://api.github.com"
# and a valid GitHub token with repo + admin:org scope (admin:org is
# required to create repositories inside an organization).
#
# Renaming a repository via var.name is not supported — the update_path
# uses the current name, so a rename would fail. Destroy+recreate instead.

locals {
  body = merge(
    {
      name       = var.name
      visibility = var.visibility
      auto_init  = var.auto_init
    },
    var.description != null ? { description = var.description } : {},
    var.homepage != null ? { homepage = var.homepage } : {},
    var.gitignore_template != null ? { gitignore_template = var.gitignore_template } : {},
    var.license_template != null ? { license_template = var.license_template } : {},
    var.has_issues != null ? { has_issues = var.has_issues } : {},
    var.has_projects != null ? { has_projects = var.has_projects } : {},
    var.has_wiki != null ? { has_wiki = var.has_wiki } : {},
    var.has_downloads != null ? { has_downloads = var.has_downloads } : {},
    var.delete_branch_on_merge != null ? { delete_branch_on_merge = var.delete_branch_on_merge } : {},
    var.allow_squash_merge != null ? { allow_squash_merge = var.allow_squash_merge } : {},
    var.allow_merge_commit != null ? { allow_merge_commit = var.allow_merge_commit } : {},
    var.allow_rebase_merge != null ? { allow_rebase_merge = var.allow_rebase_merge } : {},
    var.allow_auto_merge != null ? { allow_auto_merge = var.allow_auto_merge } : {},
  )
}

resource "rest_resource" "repository" {
  path            = "/orgs/${var.organization}/repos"
  create_method   = "POST"
  update_method   = "PATCH"
  check_existance = var.check_existance

  read_path   = "/repos/${var.organization}/${var.name}"
  update_path = "/repos/${var.organization}/${var.name}"
  delete_path = "/repos/${var.organization}/${var.name}"

  body = local.body

  output_attrs = toset([
    "id",
    "node_id",
    "name",
    "full_name",
    "private",
    "visibility",
    "html_url",
    "ssh_url",
    "clone_url",
    "default_branch",
  ])

  # GitHub's POST /orgs/{org}/repos returns 201 immediately, but the
  # GET /repos/{org}/{name} endpoint can 404 for several seconds afterward
  # due to backend replication lag. Without this poller, the provider's
  # post-create read fails, the state is discarded, and terraform raises
  # "Missing Resource State After Create". Poll the read_path until it
  # returns 200, tolerating 404s as the pending state.
  poll_create = {
    status_locator    = "code"
    default_delay_sec = 5
    status = {
      success = "200"
      pending = ["404"]
    }
  }
}
