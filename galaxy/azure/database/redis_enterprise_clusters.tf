# ── Redis Enterprise Clusters ─────────────────────────────────────────────────

variable "azure_redis_enterprise_clusters" {
  type = map(object({
    subscription_id       = optional(string)
    resource_group_name   = string
    cluster_name          = optional(string, null)
    location              = optional(string, null)
    sku_name              = string
    sku_capacity          = optional(number, null)
    zones                 = optional(list(string), null)
    minimum_tls_version   = optional(string, "1.2")
    high_availability     = optional(string, null)
    public_network_access = optional(string, null)
    tags                  = optional(map(string), null)
  }))
  description = "Map of Redis Enterprise clusters to create."
  default     = {}
}

locals {
  azure_redis_enterprise_clusters = provider::rest::resolve_map(
    local._ctx_l0b,
    merge(try(local._yaml_raw.azure_redis_enterprise_clusters, {}), var.azure_redis_enterprise_clusters)
  )
  _rec_ctx = provider::rest::merge_with_outputs(local.azure_redis_enterprise_clusters, module.azure_redis_enterprise_clusters)
}

module "azure_redis_enterprise_clusters" {
  source   = "./modules/azure/redis_enterprise_cluster"
  for_each = local.azure_redis_enterprise_clusters

  depends_on = [module.azure_resource_groups]

  subscription_id       = try(each.value.subscription_id, var.subscription_id)
  resource_group_name   = each.value.resource_group_name
  cluster_name          = try(each.value.cluster_name, null) != null ? each.value.cluster_name : each.key
  location              = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  sku_name              = each.value.sku_name
  sku_capacity          = try(each.value.sku_capacity, null)
  zones                 = try(each.value.zones, null)
  minimum_tls_version   = try(each.value.minimum_tls_version, "1.2")
  high_availability     = try(each.value.high_availability, null)
  public_network_access = try(each.value.public_network_access, null)
  tags                  = try(each.value.tags, null)
  check_existance       = var.check_existance
}
