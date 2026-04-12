# ── K8s Variables ─────────────────────────────────────────────────────────────
# Per-cluster credentials for K8s API access via the rest.k8s provider.
# tf.sh populates this from existing kind clusters using `kubectl`.

variable "k8s_cluster_credentials" {
  type = map(object({
    endpoint = string
    token    = string
  }))
  default     = {}
  sensitive   = true
  description = <<-EOT
    Per-cluster K8s API credentials. Map keys match k8s_kind_clusters YAML keys.
    - endpoint: kube-apiserver URL (e.g. https://127.0.0.1:6443)
    - token: Bearer token for authentication
    tf.sh populates via TF_VAR_k8s_cluster_credentials.
  EOT
}

variable "k8s_aks_cluster_credentials" {
  type = map(object({
    endpoint = string
    token    = string
  }))
  default     = {}
  sensitive   = true
  description = <<-EOT
    Per-AKS-cluster K8s API credentials. Map keys are AKS cluster NAMES
    (matching azure_managed_clusters.<key>.cluster_name).
    - endpoint: AKS private/public FQDN (e.g. https://dns-xxx.privatelink.swedencentral.azmk8s.io)
    - token: Azure AD bearer token for AKS audience (6dae42f8-4368-4678-94ff-3960e28e3630)
    tf.sh populates via TF_VAR_k8s_aks_cluster_credentials.
  EOT
}
