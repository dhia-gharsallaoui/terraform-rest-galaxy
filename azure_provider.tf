# ── Azure Provider Configuration ──────────────────────────────────────────────
# Uses OAuth2 refresh token for auto-renewal during long operations (e.g. VPN GW ~30 min).
# tf.sh injects TF_VAR_azure_refresh_token and TF_VAR_azure_token_url automatically.
#
# Fallback for quick manual runs:
#   export TF_VAR_azure_access_token=$(az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)

provider "rest" {
  base_url = "https://management.azure.com"

  security = var.azure_refresh_token != null ? {
    oauth2 = {
      refresh_token = {
        token_url     = var.azure_token_url
        refresh_token = var.azure_refresh_token
        client_id     = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
        scopes        = ["https://management.azure.com/.default"]
      }
    }
  } : null

  header = var.azure_refresh_token == null && var.azure_access_token != null ? {
    Authorization = "Bearer ${var.azure_access_token}"
  } : {}

  named_auth = var.named_auth

  client = {
    retry = {
      status_codes    = [409, 429, 500, 502, 503]
      count           = 5
      wait_in_sec     = 2
      max_wait_in_sec = 120
    }
  }

  # Ref-resolver tokens for validate_externals and provider functions
  arm_token         = var.azure_access_token
  arm_tenant_tokens = var.arm_tenant_tokens
  graph_token       = var.graph_access_token
  github_token      = var.github_token
  fail_on_warning   = var.fail_on_warning
}
