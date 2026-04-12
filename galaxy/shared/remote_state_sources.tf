# ── Remote State Data Sources ─────────────────────────────────────────────────
# Dynamically fetches outputs from upstream Terraform states stored in the
# same Azure Storage backend. Feeds into the existing ref: resolution
# context via remote_states.
#
# Usage:
#   terraform plan \
#     -var='remote_state_backend={"resource_group_name":"rg-terraform-state","storage_account_name":"stterraformstate001","container_name":"tfstate"}' \
#     -var='remote_state_keys={"identity":"identity.tfstate","networking":"networking.tfstate"}'

variable "remote_state_backend" {
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    use_azuread_auth     = optional(bool, true)
  })
  default     = null
  description = "Azure Storage backend config for remote state lookups. null = no remote state data sources."
}

variable "remote_state_keys" {
  type        = map(string)
  default     = {}
  description = <<-EOT
    Map of logical name → state key for remote state data sources.
    Each entry creates a data.terraform_remote_state that is merged into
    the ref: resolution context under remote_states.<name>.

    Example: { identity = "identity.tfstate", networking = "networking.tfstate" }
  EOT
}

data "terraform_remote_state" "this" {
  for_each = var.remote_state_backend != null ? var.remote_state_keys : {}

  backend = "azurerm"
  config = {
    resource_group_name  = var.remote_state_backend.resource_group_name
    storage_account_name = var.remote_state_backend.storage_account_name
    container_name       = var.remote_state_backend.container_name
    key                  = each.value
    use_azuread_auth     = var.remote_state_backend.use_azuread_auth
  }
}

locals {
  _remote_states_from_backend = {
    for k, v in data.terraform_remote_state.this : k => v.outputs
  }
}
