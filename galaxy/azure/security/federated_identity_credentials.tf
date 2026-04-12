# ── Federated Identity Credentials ────────────────────────────────────────────

variable "azure_federated_identity_credentials" {
  type = map(object({
    subscription_id           = optional(string)
    resource_group_name       = string
    identity_name             = string
    federated_credential_name = string
    issuer                    = string
    subject                   = string
    audiences                 = optional(list(string), ["api://AzureADTokenExchange"])
    _tenant                   = optional(string, null)
  }))
  description = "Map of federated identity credentials to create for workload identity federation."
  default     = {}
}

locals {
  azure_federated_identity_credentials = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_federated_identity_credentials, {}), var.azure_federated_identity_credentials)
  )
  _fic_ctx = provider::rest::merge_with_outputs(local.azure_federated_identity_credentials, module.azure_federated_identity_credentials)
}

module "azure_federated_identity_credentials" {
  source   = "./modules/azure/federated_identity_credential"
  for_each = local.azure_federated_identity_credentials

  depends_on = [module.azure_user_assigned_identities, module.azure_managed_clusters]

  subscription_id           = try(each.value.subscription_id, var.subscription_id)
  resource_group_name       = each.value.resource_group_name
  identity_name             = each.value.identity_name
  federated_credential_name = each.value.federated_credential_name
  issuer                    = each.value.issuer
  subject                   = each.value.subject
  audiences                 = try(each.value.audiences, ["api://AzureADTokenExchange"])
  check_existance           = var.check_existance

  # Cross-tenant: if _tenant is set, override the Authorization header
  auth_ref = try(each.value._tenant, null)
}
