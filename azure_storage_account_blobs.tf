# ── Storage Account Blobs (Data Plane) ────────────────────────────────────────
#
# This resource type uses the Blob Storage DATA-PLANE API, not ARM.
# Base URL: https://{account_name}.blob.core.windows.net
# Auth scope: https://storage.azure.com/.default (DIFFERENT from management.azure.com)
#
# IMPORTANT — Single-account constraint:
#   Terraform providers cannot have per-resource base URLs. All blobs managed in
#   this root module share one blob endpoint, configured via var.storage_account_name.
#   To manage blobs across multiple storage accounts, use separate Terraform
#   configurations (each with its own var.storage_account_name).
#
# Obtain a storage.azure.com scoped token:
#   export TF_VAR_storage_access_token=$(az account get-access-token \
#     --resource https://storage.azure.com --query accessToken -o tsv)

# ── Variables ─────────────────────────────────────────────────────────────────

variable "storage_account_name" {
  type        = string
  default     = null
  description = <<-EOT
    The name of the storage account whose blob endpoint is used as the provider
    base URL: https://{storage_account_name}.blob.core.windows.net.

    Required when var.azure_storage_account_blobs is non-empty.
    All blobs in var.azure_storage_account_blobs must belong to this account.
  EOT
}

variable "storage_access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = <<-EOT
    Azure AD bearer token with scope https://storage.azure.com/.default.
    Used by the blob storage data-plane provider alias.

    Obtain with:
      az account get-access-token --resource https://storage.azure.com --query accessToken -o tsv

    This token is DIFFERENT from var.azure_access_token (management.azure.com scope).
    Required when var.azure_storage_account_blobs is non-empty and auth_mode = "token".
  EOT
}

variable "azure_storage_account_blobs" {
  type = map(object({
    account_name    = string
    container_name  = string
    blob_name       = string
    content         = optional(string, null)
    content_type    = optional(string, "application/octet-stream")
    blob_type       = optional(string, "BlockBlob")
    metadata        = optional(map(string), null)
    access_tier     = optional(string, null)
    auth_mode       = optional(string, "token")
    sas_token       = optional(string, null)
    check_existance = optional(bool, null)
  }))
  description = <<-EOT
    Map of blobs to create or manage in Azure Blob Storage (data-plane API).
    Each map key acts as the for_each identifier and must be unique.

    All blobs must belong to the same storage account (var.storage_account_name).
    For blobs in different accounts, use separate Terraform configurations.

    Auth modes:
      "token" — Azure AD bearer token (scope: https://storage.azure.com/.default)
                Set var.storage_access_token to supply the token.
      "sas"   — SAS token per blob. Set sas_token on each entry.

    Example:
      azure_storage_account_blobs = {
        app_config = {
          account_name   = "mystorageaccount"
          container_name = "app-configs"
          blob_name      = "production/config.json"
          content_type   = "application/json"
          content        = jsonencode({ environment = "production" })
          access_tier    = "Hot"
          metadata = {
            team        = "platform"
            environment = "production"
          }
        }
      }
  EOT
  default     = {}
}

# ── Blob Storage data-plane provider ─────────────────────────────────────────
# Separate from the ARM provider (azure_provider.tf).
# base_url = https://{storage_account_name}.blob.core.windows.net
provider "rest" {
  alias    = "blob_storage"
  base_url = var.storage_account_name != null ? "https://${var.storage_account_name}.blob.core.windows.net" : "https://placeholder.blob.core.windows.net"

  security = var.storage_access_token != null ? {
    http = {
      token = {
        token = var.storage_access_token
      }
    }
  } : null

  client = {
    retry = {
      status_codes    = [429, 500, 502, 503]
      count           = 3
      wait_in_sec     = 2
      max_wait_in_sec = 30
    }
  }
}

# ── Locals — YAML merge and ref-resolution ────────────────────────────────────
locals {
  azure_storage_account_blobs = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_storage_account_blobs, {}), var.azure_storage_account_blobs)
  )
}

# ── Module ────────────────────────────────────────────────────────────────────
module "azure_storage_account_blobs" {
  source   = "./modules/azure/storage_account_blob"
  for_each = local.azure_storage_account_blobs

  providers = {
    rest = rest.blob_storage
  }

  depends_on = [module.azure_storage_account_containers]

  account_name    = each.value.account_name
  container_name  = each.value.container_name
  blob_name       = each.value.blob_name
  content         = try(each.value.content, null)
  content_type    = try(each.value.content_type, "application/octet-stream")
  blob_type       = try(each.value.blob_type, "BlockBlob")
  metadata        = try(each.value.metadata, null)
  access_tier     = try(each.value.access_tier, null)
  auth_mode       = try(each.value.auth_mode, "token")
  sas_token       = try(each.value.sas_token, null)
  check_existance = try(each.value.check_existance, var.check_existance)
}
