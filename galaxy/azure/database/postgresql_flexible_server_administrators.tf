# ── PostgreSQL Flexible Server Administrators (Entra ID) ──────────────────────

variable "azure_postgresql_flexible_server_administrators" {
  type = map(object({
    subscription_id     = optional(string)
    resource_group_name = string
    server_name         = string
    object_id           = string
    principal_type      = optional(string, "ServicePrincipal")
    principal_name      = string
    tenant_id           = string
  }))
  description = "Map of PostgreSQL Flexible Server Entra administrators to create."
  default     = {}
}

locals {
  azure_postgresql_flexible_server_administrators = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_postgresql_flexible_server_administrators, {}), var.azure_postgresql_flexible_server_administrators)
  )
  _pga_ctx = provider::rest::merge_with_outputs(local.azure_postgresql_flexible_server_administrators, module.azure_postgresql_flexible_server_administrators)
}

module "azure_postgresql_flexible_server_administrators" {
  source   = "./modules/azure/postgresql_flexible_server_administrator"
  for_each = local.azure_postgresql_flexible_server_administrators

  depends_on = [module.azure_postgresql_flexible_servers]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  server_name         = each.value.server_name
  object_id           = each.value.object_id
  principal_type      = try(each.value.principal_type, "ServicePrincipal")
  principal_name      = each.value.principal_name
  tenant_id           = each.value.tenant_id
  check_existance     = var.check_existance
}
