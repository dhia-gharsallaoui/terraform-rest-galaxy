# ── Provider behaviour ─────────────────────────────────────────────────────

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether the resource already exists before creating it. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows."
}

# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group containing the parent Foundry account."
}

variable "account_name" {
  type        = string
  description = "The name of the parent Foundry account (Microsoft.CognitiveServices/accounts)."
}

variable "location" {
  type        = string
  description = "The Azure region of the parent Foundry account. Used to validate model availability at plan time."
}

# ── Required ──────────────────────────────────────────────────────────────────

variable "deployment_name" {
  type        = string
  description = "The name of this model deployment. Must be unique within the Foundry account. Used as the deployment endpoint identifier in API calls."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,63}$", var.deployment_name))
    error_message = "deployment_name must start with alphanumeric and contain only alphanumeric, hyphens, underscores, and dots (max 64 chars)."
  }
}

variable "model_format" {
  type        = string
  description = <<-EOT
    The format/provider of the model. Determines which model catalog is used.

    Common values:
    - "OpenAI"         — Azure OpenAI models (gpt-4o, gpt-4, text-embedding-ada-002, etc.)
    - "Meta"           — Meta Llama models (via Azure AI model catalog)
    - "Mistral"        — Mistral models
    - "Microsoft"      — Microsoft Phi models
    - "Cohere"         — Cohere models

    The available formats depend on your region and subscription.
  EOT

  validation {
    condition     = length(var.model_format) > 0
    error_message = "model_format must not be empty."
  }
}

variable "model_name" {
  type        = string
  description = <<-EOT
    The name of the model to deploy. Must match an available model in your region.

    Common OpenAI models:
    - "gpt-4o"                — GPT-4o (recommended for most use cases)
    - "gpt-4o-mini"           — GPT-4o Mini (cost-optimised)
    - "gpt-4"                 — GPT-4
    - "gpt-35-turbo"          — GPT-3.5 Turbo
    - "text-embedding-ada-002" — Ada v2 embeddings
    - "text-embedding-3-small" — Ada 3 Small embeddings
    - "text-embedding-3-large" — Ada 3 Large embeddings
    - "dall-e-3"              — DALL-E 3 image generation
    - "whisper"               — Whisper speech-to-text
    - "tts"                   — Text-to-speech
    - "tts-hd"                — Text-to-speech HD

    A plan-time precondition validates that the model is available in var.location.
  EOT

  validation {
    condition     = length(var.model_name) > 0
    error_message = "model_name must not be empty."
  }
}

variable "sku_name" {
  type        = string
  description = <<-EOT
    The deployment SKU. Determines throughput, billing model, and availability.

    - "Standard"                    — Pay-per-token, regional capacity
    - "GlobalStandard"              — Pay-per-token, global load-balanced capacity (recommended)
    - "DataZoneStandard"            — Pay-per-token, data-zone routing
    - "ProvisionedManaged"          — Reserved throughput (PTU) — requires quota approval
    - "DataZoneProvisionedManaged"  — Reserved throughput, data-zone routing
    - "OnDemand"                    — On-demand capacity (where available)

    Use "GlobalStandard" for most production deployments unless data residency
    requirements mandate a regional or data-zone SKU.
  EOT

  validation {
    condition     = contains(["Standard", "GlobalStandard", "DataZoneStandard", "ProvisionedManaged", "DataZoneProvisionedManaged", "OnDemand"], var.sku_name)
    error_message = "sku_name must be one of: Standard, GlobalStandard, DataZoneStandard, ProvisionedManaged, DataZoneProvisionedManaged, OnDemand."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "model_version" {
  type        = string
  default     = null
  description = <<-EOT
    The specific model version to deploy (e.g. "2024-08-06" for gpt-4o).
    Leave null to use the current default version. Pin a version for
    reproducible behaviour — unpinned deployments may change on Microsoft's
    release schedule according to version_upgrade_option.
  EOT
}

variable "model_publisher" {
  type        = string
  default     = null
  description = "The model publisher. Typically not needed for OpenAI models but required for some third-party catalog models."
}

variable "model_source" {
  type        = string
  default     = null
  description = "The model source URI. Used for fine-tuned or custom models deployed from a specific registry path."
}

variable "model_source_account" {
  type        = string
  default     = null
  description = "The source account resource ID for models being cross-account deployed."
}

variable "sku_capacity" {
  type        = number
  default     = null
  description = <<-EOT
    Capacity in thousands of tokens per minute (TPM) for Standard/GlobalStandard SKUs,
    or in Provisioned Throughput Units (PTU) for ProvisionedManaged SKUs.

    Examples:
    - 10  → 10K TPM (Standard/GlobalStandard)
    - 100 → 100K TPM (GlobalStandard)
    - 300 → 300 PTU (ProvisionedManaged)

    Leave null for some SKUs that manage capacity automatically (e.g. OnDemand).
  EOT

  validation {
    condition     = var.sku_capacity == null || var.sku_capacity > 0
    error_message = "sku_capacity must be a positive integer when set."
  }
}

variable "version_upgrade_option" {
  type        = string
  default     = "OnceNewDefaultVersionAvailable"
  description = <<-EOT
    Controls automatic version upgrades for the deployed model:

    - "OnceNewDefaultVersionAvailable" (default): Automatically upgrades to the new
      default version when Microsoft releases one. Minimal maintenance, but behaviour
      may change.
    - "OnceCurrentVersionExpired": Stays on the pinned version until it reaches
      end-of-life, then upgrades. Balance between stability and maintenance.
    - "NoAutoUpgrade": Never automatically upgrades. Requires manual version
      management. Use when strict version pinning is required for compliance.
  EOT

  validation {
    condition     = contains(["OnceNewDefaultVersionAvailable", "OnceCurrentVersionExpired", "NoAutoUpgrade"], var.version_upgrade_option)
    error_message = "version_upgrade_option must be one of: OnceNewDefaultVersionAvailable, OnceCurrentVersionExpired, NoAutoUpgrade."
  }
}

variable "rai_policy_name" {
  type        = string
  default     = null
  description = <<-EOT
    The name of the Responsible AI (RAI) content filtering policy to apply to this deployment.
    Leave null to use the account default policy. Custom policies can be created in
    Azure AI Foundry Studio under Content Filters.
  EOT
}

variable "scale_type" {
  type        = string
  default     = null
  description = "The scale type for scaleSettings: 'Standard' or 'Manual'. Typically managed automatically — only set if instructed by Azure support."

  validation {
    condition     = var.scale_type == null || contains(["Standard", "Manual"], var.scale_type)
    error_message = "scale_type must be 'Standard' or 'Manual'."
  }
}

variable "scale_capacity" {
  type        = number
  default     = null
  description = "The capacity for scaleSettings. Typically set together with scale_type."

  validation {
    condition     = var.scale_capacity == null || var.scale_capacity > 0
    error_message = "scale_capacity must be a positive integer when set."
  }
}

variable "capacity_settings_designated_capacity" {
  type        = number
  default     = null
  description = "The designated (reserved) capacity for this deployment. Used in multi-deployment capacity management scenarios."

  validation {
    condition     = var.capacity_settings_designated_capacity == null || var.capacity_settings_designated_capacity >= 0
    error_message = "capacity_settings_designated_capacity must be a non-negative integer when set."
  }
}

variable "capacity_settings_priority" {
  type        = number
  default     = null
  description = "The priority for capacity allocation when multiple deployments share capacity. Lower values = higher priority."

  validation {
    condition     = var.capacity_settings_priority == null || var.capacity_settings_priority >= 0
    error_message = "capacity_settings_priority must be a non-negative integer when set."
  }
}

variable "parent_deployment_name" {
  type        = string
  default     = null
  description = "The name of the parent deployment. Used for hierarchical deployment configurations."
}

variable "spillover_deployment_name" {
  type        = string
  default     = null
  description = "The name of the fallback deployment to handle overflow traffic when this deployment reaches capacity."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to the deployment resource."
}
