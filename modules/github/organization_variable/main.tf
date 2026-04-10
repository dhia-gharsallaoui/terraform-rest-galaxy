# Source: GitHub REST API
#   api        : GitHub REST API v2022-11-28
#   resource   : actions/variables (organization-scoped)
#   create     : POST   /orgs/{org}/actions/variables          (synchronous)
#   read       : GET    /orgs/{org}/actions/variables/{name}
#   update     : PATCH  /orgs/{org}/actions/variables/{name}
#   delete     : DELETE /orgs/{org}/actions/variables/{name}
#
# NOTE: This module requires a rest provider configured with
#   base_url = "https://api.github.com"
# and a valid GitHub token with admin:org scope.
#
# visibility = "selected" requires var.selected_repository_ids to be
# set to a non-empty list of numeric repository IDs.

locals {
  body = merge(
    {
      name       = var.name
      value      = var.value
      visibility = var.visibility
    },
    var.selected_repository_ids != null ? { selected_repository_ids = var.selected_repository_ids } : {},
  )
}

resource "rest_resource" "organization_variable" {
  path          = "/orgs/${var.organization}/actions/variables"
  create_method = "POST"
  update_method = "PATCH"

  read_path   = "/orgs/${var.organization}/actions/variables/${var.name}"
  update_path = "/orgs/${var.organization}/actions/variables/${var.name}"
  delete_path = "/orgs/${var.organization}/actions/variables/${var.name}"

  body = local.body

  output_attrs = toset([
    "name",
    "value",
    "visibility",
    "created_at",
    "updated_at",
  ])
}
