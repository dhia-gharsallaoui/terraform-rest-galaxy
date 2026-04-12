# ── Redis Enterprise Databases ────────────────────────────────────────────────

variable "azure_redis_enterprise_databases" {
  type = map(object({
    subscription_id            = optional(string)
    resource_group_name        = string
    cluster_name               = string
    database_name              = optional(string, "default")
    client_protocol            = optional(string, "Encrypted")
    port                       = optional(number, 10000)
    clustering_policy          = optional(string, "OSSCluster")
    eviction_policy            = optional(string, "VolatileLRU")
    access_keys_authentication = optional(string, null)
    modules = optional(list(object({
      name = string
      args = optional(string)
    })), null)
    persistence = optional(object({
      aof_enabled   = optional(bool)
      aof_frequency = optional(string)
      rdb_enabled   = optional(bool)
      rdb_frequency = optional(string)
    }), null)
  }))
  description = "Map of Redis Enterprise databases to create."
  default     = {}
}

locals {
  azure_redis_enterprise_databases = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_redis_enterprise_databases, {}), var.azure_redis_enterprise_databases)
  )
  _red_ctx = provider::rest::merge_with_outputs(local.azure_redis_enterprise_databases, module.azure_redis_enterprise_databases)
}

module "azure_redis_enterprise_databases" {
  source   = "./modules/azure/redis_enterprise_database"
  for_each = local.azure_redis_enterprise_databases

  depends_on = [module.azure_redis_enterprise_clusters]

  subscription_id            = try(each.value.subscription_id, var.subscription_id)
  resource_group_name        = each.value.resource_group_name
  cluster_name               = each.value.cluster_name
  database_name              = try(each.value.database_name, "default")
  client_protocol            = try(each.value.client_protocol, "Encrypted")
  port                       = try(each.value.port, 10000)
  clustering_policy          = try(each.value.clustering_policy, "OSSCluster")
  eviction_policy            = try(each.value.eviction_policy, "VolatileLRU")
  access_keys_authentication = try(each.value.access_keys_authentication, null)
  modules                    = try(each.value.modules, null)
  persistence                = try(each.value.persistence, null)
  check_existance            = var.check_existance
}
