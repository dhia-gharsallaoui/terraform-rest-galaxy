# Source: GitHub REST API
#   api        : GitHub REST API v2022-11-28
#   resource   : actions/secrets (environment-scoped)
#   public_key : GET    /repos/{owner}/{repo}/environments/{environment_name}/secrets/public-key
#   create     : PUT    /repos/{owner}/{repo}/environments/{environment_name}/secrets/{secret_name}  (synchronous)
#   read       : GET    /repos/{owner}/{repo}/environments/{environment_name}/secrets/{secret_name}
#   delete     : DELETE /repos/{owner}/{repo}/environments/{environment_name}/secrets/{secret_name}
#
# The GitHub Secrets API requires the secret value to be encrypted using
# NaCl sealed-box encryption (libsodium crypto_box_seal) with the
# environment's public key before upload. The provider::rest::nacl_seal
# function handles this. The encryption key is fetched per-environment
# (it differs from the repository-level key).
#
# NOTE: The public key data source is refreshed at plan time, so this
# module requires a valid GitHub token with repo scope during plan —
# placeholder tokens will fail. Unit tests that exercise this module
# must either use a real token or mock the rest provider.

# ── Fetch the environment's NaCl public key ──────────────────────────────────
data "rest_resource" "public_key" {
  id = "/repos/${var.owner}/${var.repo}/environments/${var.environment_name}/secrets/public-key"

  output_attrs = toset([
    "key",
    "key_id",
  ])
}

# ── Encrypt and upload the secret ────────────────────────────────────────────
resource "rest_resource" "secret" {
  path          = "/repos/${var.owner}/${var.repo}/environments/${var.environment_name}/secrets/${var.secret_name}"
  create_method = "PUT"

  read_path   = "/repos/${var.owner}/${var.repo}/environments/${var.environment_name}/secrets/${var.secret_name}"
  delete_path = "/repos/${var.owner}/${var.repo}/environments/${var.environment_name}/secrets/${var.secret_name}"

  body = {
    encrypted_value = provider::rest::nacl_seal(var.plaintext_value, data.rest_resource.public_key.output.key)
    key_id          = data.rest_resource.public_key.output.key_id
  }

  # PUT returns empty body (201/204); GET returns name + created_at + updated_at (no value)
  output_attrs = toset([
    "name",
    "created_at",
    "updated_at",
  ])
}
