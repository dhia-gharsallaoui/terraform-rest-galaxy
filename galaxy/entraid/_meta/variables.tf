# ── Entra ID Variables ────────────────────────────────────────────────────────

variable "graph_access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Pre-fetched access token for the graph.microsoft.com audience. Fallback when graph_refresh_token is not set."
}

variable "graph_refresh_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Azure CLI refresh token for the graph.microsoft.com audience. Auto-renews during long operations. Injected by tf.sh from the MSAL token cache."
}

variable "graph_token_url" {
  type        = string
  default     = null
  description = "OAuth2 token endpoint URL for Graph. Injected by tf.sh."
}
