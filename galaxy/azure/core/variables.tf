# ── Shared Variables ──────────────────────────────────────────────────────────

variable "default_location" {
  type        = string
  default     = null
  description = "Default Azure region for resources that omit an explicit location."
}

variable "azure_access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Pre-fetched Azure access token for the management.azure.com audience. Fallback when azure_refresh_token is not set."
}

variable "azure_refresh_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Azure CLI refresh token for the management.azure.com audience. Auto-renews during long operations. Injected by tf.sh from the MSAL token cache."
}

variable "azure_token_url" {
  type        = string
  default     = null
  description = "OAuth2 token endpoint URL (e.g. https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token). Injected by tf.sh."
}

variable "arm_tenant_tokens" {
  type        = map(string)
  sensitive   = true
  default     = {}
  description = <<-EOT
    Map of tenant_id → ARM bearer token for cross-tenant access.
    Used by validate_externals / ref-resolver for cross-tenant lookups.
    Example:
      export TF_VAR_arm_tenant_tokens='{"4fcc1d67-...": "'$(az account get-access-token --resource https://management.azure.com --tenant 4fcc1d67-... --query accessToken -o tsv)'" }'
  EOT
}

variable "named_auth" {
  type        = any
  sensitive   = true
  default     = {}
  description = <<-EOT
    Named authentication configurations for cross-tenant access.
    Each entry creates an independent HTTP client with its own OAuth2 transport.
    Resources reference entries via auth_ref = "<key>".
    Keys are tenant IDs; values follow the provider security schema.
    Example:
      named_auth = {
        "4f8f6e1e-..." = { oauth2 = { refresh_token = { token_url = "...", refresh_token = "...", client_id = "...", scopes = ["..."] } } }
      }
  EOT
}

variable "subscription_id" {
  type        = string
  default     = null
  description = "Default Azure subscription ID. Used when a resource entry omits subscription_id."
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Default Azure AD tenant ID. Used when a key vault entry omits tenant_id."
}

variable "caller_object_id" {
  type        = string
  default     = null
  description = "Object ID of the current caller (user or service principal). Auto-populated by tf.sh. Available in YAML as ref:caller.object_id."
}

variable "check_existance" {
  type        = bool
  default     = false
  description = "Check whether resources already exist before creating them. When true, the provider performs a GET before PUT and imports the resource into state if it exists. Set to true for brownfield import workflows (tf-import). Defaults to false for greenfield deployments."
}

variable "precheck_billing_access" {
  type        = bool
  default     = false
  description = "When true, billing modules call the checkAccess API before creating resources to verify the caller has the required billing permissions. Fails with a descriptive error (including PIM activation hints) if access is denied."
}

variable "config_file" {
  type        = string
  default     = null
  description = <<-EOT
    Optional path to a YAML configuration file. Resource maps defined in the
    file are merged with any directly-supplied var.* maps; direct variables
    take precedence on key collision.

    String values prefixed with "ref:" are resolved against the reference
    context at plan time.  Use "ref:path|default" for optional references.

    Example:
      TF_VAR_config_file=config.yaml terraform apply
  EOT
}

variable "remote_states" {
  type        = any
  default     = {}
  description = <<-EOT
    Map of remote state outputs to expose in ref: resolution context.

    Example:
      remote_states = {
        hub = data.terraform_remote_state.hub.outputs
      }

    Then in config.yaml:
      resource_group_name: ref:remote_states.hub.values.resource_groups.networking.name
  EOT
}

variable "externals" {
  type        = any
  default     = {}
  description = <<-EOT
    Static external references — data about resources NOT managed by this
    Terraform state, but needed as ref: targets by managed resources.

    Values can be supplied via the HCL variable or via the YAML config file
    under the top-level `externals` key. The two sources are merged (YAML
    first, HCL overrides on key collision).

    The map is injected into the ref: resolution context at Layer 0,
    making it available to every resource at every layer.

    Example (YAML):
      externals:
        azure_tenants:
          corp:
            tenant_id: "4fcc1d67-2ccc-4e50-99c7-93a41aecbca3"
            domain: "contoso.onmicrosoft.com"
        github_organizations:
          contoso:
            org_name: contoso-corp
        azure_resource_groups:
          legacy:
            resource_group_name: rg-legacy
            location: westeurope

    Then in config.yaml:
      tenant_id: ref:externals.azure_tenants.corp.tenant_id
      resource_group_name: ref:externals.azure_resource_groups.legacy.resource_group_name
  EOT
}
