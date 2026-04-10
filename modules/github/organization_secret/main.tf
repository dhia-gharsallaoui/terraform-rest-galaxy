# Source: GitHub REST API
#   api        : GitHub REST API v2022-11-28
#   resource   : actions/secrets (organization-scoped)
#   public_key : GET    /orgs/{org}/actions/secrets/public-key
#   create     : PUT    /orgs/{org}/actions/secrets/{secret_name}  (synchronous)
#   read       : GET    /orgs/{org}/actions/secrets/{secret_name}
#   delete     : DELETE /orgs/{org}/actions/secrets/{secret_name}
#
# The GitHub Secrets API requires the secret value to be encrypted using
# NaCl sealed-box encryption (libsodium crypto_box_seal) with the
# organization's public key before upload. The provider::rest::nacl_seal
# function handles this.
#
# visibility = "selected" requires var.selected_repository_ids to be
# set to a non-empty list of numeric repository IDs.
#
# NOTE: The public key data source is refreshed at plan time, so this
# module requires a valid GitHub token with admin:org scope during plan.

# ── Fetch the organization's NaCl public key ─────────────────────────────────
data "rest_resource" "public_key" {
  id = "/orgs/${var.organization}/actions/secrets/public-key"

  output_attrs = toset([
    "key",
    "key_id",
  ])
}

# ── Encrypt and upload the secret ────────────────────────────────────────────
locals {
  body = merge(
    {
      encrypted_value = provider::rest::nacl_seal(var.plaintext_value, data.rest_resource.public_key.output.key)
      key_id          = data.rest_resource.public_key.output.key_id
      visibility      = var.visibility
    },
    var.selected_repository_ids != null ? { selected_repository_ids = var.selected_repository_ids } : {},
  )
}

resource "rest_resource" "secret" {
  path          = "/orgs/${var.organization}/actions/secrets/${var.secret_name}"
  create_method = "PUT"

  read_path   = "/orgs/${var.organization}/actions/secrets/${var.secret_name}"
  delete_path = "/orgs/${var.organization}/actions/secrets/${var.secret_name}"

  body = local.body

  # PUT returns empty body (201/204); GET returns name + visibility + created_at + updated_at (no value)
  output_attrs = toset([
    "name",
    "visibility",
    "created_at",
    "updated_at",
  ])
}
