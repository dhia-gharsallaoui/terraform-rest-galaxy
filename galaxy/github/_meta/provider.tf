# ── GitHub Provider Configuration ─────────────────────────────────────────────
# Supply a GitHub token:
#   export TF_VAR_github_token=$(gh auth token)

provider "rest" {
  alias    = "github"
  base_url = "https://api.github.com"
  security = {
    http = {
      token = {
        token = coalesce(var.github_token, "not-configured")
      }
    }
  }
}
