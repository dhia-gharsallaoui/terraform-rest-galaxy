# ── Provider-agnostic Variables ───────────────────────────────────────────────

variable "fail_on_warning" {
  type        = bool
  default     = false
  description = "When true, validate_externals raises an error (failing the plan) if any API validation produces a warning (e.g. 404, permission error). Defaults to false."
}

variable "docker_available" {
  type        = bool
  default     = true
  description = "Whether Docker is running. Set automatically by tf.sh when k8s_kind_clusters are present. When false, kind cluster creation is blocked at plan time."
}
