# Source: GitHub REST API
#   api        : GitHub REST API v2022-11-28
#   resource   : actions/variables (environment-scoped)
#   create     : POST   /repos/{owner}/{repo}/environments/{environment_name}/variables         (synchronous)
#   read       : GET    /repos/{owner}/{repo}/environments/{environment_name}/variables/{name}
#   update     : PATCH  /repos/{owner}/{repo}/environments/{environment_name}/variables/{name}
#   delete     : DELETE /repos/{owner}/{repo}/environments/{environment_name}/variables/{name}
#
# NOTE: This module requires a rest provider configured with
#   base_url = "https://api.github.com"
# and a valid GitHub token with repo scope.

resource "rest_resource" "environment_variable" {
  path          = "/repos/${var.owner}/${var.repo}/environments/${var.environment_name}/variables"
  create_method = "POST"
  update_method = "PATCH"

  read_path   = "/repos/${var.owner}/${var.repo}/environments/${var.environment_name}/variables/${var.name}"
  update_path = "/repos/${var.owner}/${var.repo}/environments/${var.environment_name}/variables/${var.name}"
  delete_path = "/repos/${var.owner}/${var.repo}/environments/${var.environment_name}/variables/${var.name}"

  body = {
    name  = var.name
    value = var.value
  }

  output_attrs = toset([
    "name",
    "value",
    "created_at",
    "updated_at",
  ])
}
