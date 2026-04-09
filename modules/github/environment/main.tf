# Source: GitHub REST API
#   api        : GitHub REST API v2022-11-28
#   resource   : repos (deployments/environments)
#   create     : PUT    /repos/{owner}/{repo}/environments/{environment_name}  (idempotent, upsert)
#   read       : GET    /repos/{owner}/{repo}/environments/{environment_name}
#   update     : PUT    /repos/{owner}/{repo}/environments/{environment_name}  (same as create)
#   delete     : DELETE /repos/{owner}/{repo}/environments/{environment_name}
#
# NOTE: This module requires a rest provider configured with
#   base_url = "https://api.github.com"
# and a valid GitHub token with repo scope.
#
# The deployment_branch_policy spec requires that exactly one of
# protected_branches or custom_branch_policies is true. To allow all
# branches to deploy, set var.deployment_branch_policy = null.

locals {
  # GitHub rejects the request with 422 "Required reviewers must have at
  # least one reviewer to set prevent_self_review" whenever the body
  # includes prevent_self_review without a non-empty reviewers list, so we
  # only include prevent_self_review when reviewers are also provided.
  body = merge(
    var.wait_timer != null ? { wait_timer = var.wait_timer } : {},
    (var.prevent_self_review != null && var.reviewers != null && length(coalesce(var.reviewers, [])) > 0) ? { prevent_self_review = var.prevent_self_review } : {},
    var.reviewers != null ? { reviewers = var.reviewers } : {},
    {
      deployment_branch_policy = var.deployment_branch_policy
    },
  )
}

resource "rest_resource" "environment" {
  path          = "/repos/${var.owner}/${var.repo}/environments/${var.name}"
  create_method = "PUT"
  update_method = "PUT"

  read_path   = "/repos/${var.owner}/${var.repo}/environments/${var.name}"
  update_path = "/repos/${var.owner}/${var.repo}/environments/${var.name}"
  delete_path = "/repos/${var.owner}/${var.repo}/environments/${var.name}"

  body = local.body

  output_attrs = toset([
    "id",
    "node_id",
    "name",
    "url",
    "html_url",
    "created_at",
    "updated_at",
  ])
}
