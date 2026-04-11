# ── Provider behaviour ─────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it."
}

# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group name containing the cluster."
}

variable "cluster_rp" {
  type        = string
  default     = "Microsoft.Kubernetes"
  description = "The resource provider of the cluster (e.g. Microsoft.Kubernetes for Arc, Microsoft.ContainerService for AKS)."
}

variable "cluster_resource_name" {
  type        = string
  default     = "connectedClusters"
  description = "The resource type name of the cluster (e.g. connectedClusters, managedClusters)."
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster."
}

variable "extension_name" {
  type        = string
  description = "The name of the extension instance."
}

# ── Required body properties ──────────────────────────────────────────────────

variable "extension_type" {
  type        = string
  description = "Type of the Extension (e.g. microsoft.monitor.pipelinecontroller, microsoft.azuremonitor.containers)."
}

# ── Optional body properties ──────────────────────────────────────────────────

variable "auto_upgrade_minor_version" {
  type        = bool
  default     = true
  description = "Flag to note if this extension participates in auto upgrade of minor version."
}

variable "release_train" {
  type        = string
  default     = null
  description = "ReleaseTrain this extension participates in for auto-upgrade (e.g. Stable, Preview). Only if autoUpgradeMinorVersion is true."
}

variable "version_pin" {
  type        = string
  default     = null
  description = "User-specified version to pin this extension to. autoUpgradeMinorVersion must be false."
}

variable "scope" {
  type = object({
    cluster = optional(object({
      release_namespace = optional(string, null)
    }), null)
    namespace = optional(object({
      target_namespace = optional(string, null)
    }), null)
  })
  default     = null
  description = "Scope of the extension — either Cluster or Namespace (not both)."
}

variable "configuration_settings" {
  type        = map(string)
  default     = null
  description = "Configuration settings as name-value pairs."
}

variable "configuration_protected_settings" {
  type        = map(string)
  default     = null
  sensitive   = true
  description = "Sensitive configuration settings as name-value pairs."
}

variable "identity_type" {
  type        = string
  default     = null
  description = "The identity type for the extension (e.g. SystemAssigned)."
}

variable "plan" {
  type = object({
    name      = string
    publisher = string
    product   = string
  })
  default     = null
  description = "Plan for the resource (marketplace extensions)."
}

# ── Architecture gate ─────────────────────────────────────────────────────────

variable "cluster_node_architecture" {
  type        = string
  default     = null
  description = "The CPU architecture of the cluster worker nodes (e.g. amd64, arm64). Auto-detected from K8s node labels at the root level. When set, the module checks the extension type against a built-in registry of known architecture requirements."
}

# ── Auth ─────────────────────────────────────────────────────────────────────

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant auth."
}
