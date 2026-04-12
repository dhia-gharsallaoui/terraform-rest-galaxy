# ── Kubernetes Provider Configuration ─────────────────────────────────────────
# K8s resources use `rest.k8s` to call kube-apiserver REST APIs directly.
#
# Architecture:
#   - kind clusters are created by the `kind` provider
#   - rest_token creates a ServiceAccount + Bearer token per cluster
#     using the kubeconfig with client cert auth (runs inside the Terraform graph)
#   - K8s modules accept cluster_endpoint and use absolute URLs in `path`
#     (resty bypasses base_url for absolute URLs)
#   - Auth: header with Bearer token per resource (stored in state for destroy)
#   - TLS:  tls_insecure_skip_verify=true (kind uses self-signed certs)
#   - Single-pass apply: everything in one `terraform apply`
#
# Required: kind CLI + Docker running.

provider "rest" {
  alias    = "k8s"
  base_url = "https://127.0.0.1"

  client = {
    tls_insecure_skip_verify = true
  }
}
