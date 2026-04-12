# ── PostgreSQL Flexible Servers ────────────────────────────────────────────────

variable "azure_postgresql_flexible_servers" {
  type = map(object({
    subscription_id              = string
    resource_group_name          = string
    server_name                  = optional(string, null)
    location                     = optional(string, null)
    sku_name                     = optional(string, "Standard_D2ds_v5")
    sku_tier                     = optional(string, "GeneralPurpose")
    server_version               = optional(string, "16")
    administrator_login          = optional(string, null)
    administrator_login_password = optional(string, null)
    active_directory_auth        = optional(string, null)
    password_auth                = optional(string, null)
    auth_tenant_id               = optional(string, null)
    storage_size_gb              = optional(number, 32)
    storage_auto_grow            = optional(string, null)
    storage_tier                 = optional(string, null)
    backup_retention_days        = optional(number, null)
    geo_redundant_backup         = optional(string, null)
    ha_mode                      = optional(string, null)
    ha_standby_availability_zone = optional(string, null)
    delegated_subnet_id          = optional(string, null)
    private_dns_zone_id          = optional(string, null)
    public_network_access        = optional(string, null)
    availability_zone            = optional(string, null)
    maintenance_window = optional(object({
      custom_window = optional(string, "Disabled")
      start_hour    = optional(number, 0)
      start_minute  = optional(number, 0)
      day_of_week   = optional(number, 0)
    }), null)
    tags = optional(map(string), null)
  }))
  description = "Map of PostgreSQL Flexible Servers to create."
  default     = {}
}

locals {
  azure_postgresql_flexible_servers = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_postgresql_flexible_servers, {}), var.azure_postgresql_flexible_servers)
  )
  _pg_ctx = provider::rest::merge_with_outputs(local.azure_postgresql_flexible_servers, module.azure_postgresql_flexible_servers)
}

module "azure_postgresql_flexible_servers" {
  source   = "./modules/azure/postgresql_flexible_server"
  for_each = local.azure_postgresql_flexible_servers

  depends_on = [module.azure_virtual_networks, module.azure_private_dns_zones, module.azure_managed_clusters]

  subscription_id              = try(each.value.subscription_id, var.subscription_id)
  resource_group_name          = each.value.resource_group_name
  server_name                  = try(each.value.server_name, null) != null ? each.value.server_name : each.key
  location                     = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  sku_name                     = try(each.value.sku_name, "Standard_D2ds_v5")
  sku_tier                     = try(each.value.sku_tier, "GeneralPurpose")
  server_version               = try(each.value.server_version, "16")
  administrator_login          = try(each.value.administrator_login, null)
  administrator_login_password = try(each.value.administrator_login_password, null)
  active_directory_auth        = try(each.value.active_directory_auth, null)
  password_auth                = try(each.value.password_auth, null)
  auth_tenant_id               = try(each.value.auth_tenant_id, null)
  storage_size_gb              = try(each.value.storage_size_gb, 32)
  storage_auto_grow            = try(each.value.storage_auto_grow, null)
  storage_tier                 = try(each.value.storage_tier, null)
  backup_retention_days        = try(each.value.backup_retention_days, null)
  geo_redundant_backup         = try(each.value.geo_redundant_backup, null)
  ha_mode                      = try(each.value.ha_mode, null)
  ha_standby_availability_zone = try(each.value.ha_standby_availability_zone, null)
  delegated_subnet_id          = try(each.value.delegated_subnet_id, null)
  private_dns_zone_id          = try(each.value.private_dns_zone_id, null)
  public_network_access        = try(each.value.public_network_access, null)
  availability_zone            = try(each.value.availability_zone, null)
  maintenance_window           = try(each.value.maintenance_window, null)
  tags                         = try(each.value.tags, null)
  check_existance              = var.check_existance
}
