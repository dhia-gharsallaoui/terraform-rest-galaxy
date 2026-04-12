# ── Entra ID Provider Configuration ───────────────────────────────────────────
# Preferred: refresh token (auto-renews, injected by tf.sh).
# Fallback:  static Graph access token.
#   export TF_VAR_graph_access_token=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv)

provider "rest" {
  alias    = "graph"
  base_url = "https://graph.microsoft.com"

  security = var.graph_refresh_token != null ? {
    oauth2 = {
      refresh_token = {
        token_url     = var.graph_token_url
        refresh_token = var.graph_refresh_token
        client_id     = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
        scopes        = ["https://graph.microsoft.com/.default"]
      }
    }
  } : null

  header = var.graph_refresh_token == null && var.graph_access_token != null ? {
    Authorization = "Bearer ${var.graph_access_token}"
  } : {}
}
