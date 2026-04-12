# ── Load Balancers ────────────────────────────────────────────────────────────

variable "azure_load_balancers" {
  type = map(object({
    subscription_id     = string
    resource_group_name = string
    load_balancer_name  = optional(string, null)
    location            = optional(string, null)
    sku_name            = string
    sku_tier            = optional(string, null)
    frontend_ip_configurations = optional(list(object({
      name                         = string
      subnet_id                    = optional(string)
      private_ip_address           = optional(string)
      private_ip_allocation_method = optional(string)
      public_ip_address_id         = optional(string)
      zones                        = optional(list(string))
    })), null)
    backend_address_pools = optional(list(object({
      name = string
    })), null)
    probes = optional(list(object({
      name                = string
      protocol            = string
      port                = number
      request_path        = optional(string)
      interval_in_seconds = optional(number)
      number_of_probes    = optional(number)
    })), null)
    load_balancing_rules = optional(list(object({
      name                      = string
      protocol                  = string
      frontend_port             = number
      backend_port              = number
      frontend_ip_config_name   = string
      backend_address_pool_name = string
      probe_name                = optional(string)
      idle_timeout_in_minutes   = optional(number)
      enable_floating_ip        = optional(bool)
      enable_tcp_reset          = optional(bool)
    })), null)
    inbound_nat_rules = optional(list(object({
      name                      = string
      protocol                  = string
      frontend_port_range_start = number
      frontend_port_range_end   = number
      backend_port              = number
      frontend_ip_config_name   = string
      backend_address_pool_name = optional(string)
      idle_timeout_in_minutes   = optional(number)
      enable_floating_ip        = optional(bool)
      enable_tcp_reset          = optional(bool)
    })), null)
    tags = optional(map(string), null)
  }))
  description = "Map of load balancers to create."
  default     = {}
}

locals {
  azure_load_balancers = provider::rest::resolve_map(
    local._ctx_l1,
    merge(try(local._yaml_raw.azure_load_balancers, {}), var.azure_load_balancers)
  )
  _lb_ctx = provider::rest::merge_with_outputs(local.azure_load_balancers, module.azure_load_balancers)
}

module "azure_load_balancers" {
  source   = "./modules/azure/load_balancer"
  for_each = local.azure_load_balancers

  depends_on = [module.azure_virtual_networks, module.azure_public_ip_addresses]

  subscription_id            = try(each.value.subscription_id, var.subscription_id)
  resource_group_name        = each.value.resource_group_name
  load_balancer_name         = try(each.value.load_balancer_name, null) != null ? each.value.load_balancer_name : each.key
  location                   = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  sku_name                   = each.value.sku_name
  sku_tier                   = try(each.value.sku_tier, null)
  frontend_ip_configurations = try(each.value.frontend_ip_configurations, null)
  backend_address_pools      = try(each.value.backend_address_pools, null)
  probes                     = try(each.value.probes, null)
  load_balancing_rules       = try(each.value.load_balancing_rules, null)
  inbound_nat_rules          = try(each.value.inbound_nat_rules, null)
  tags                       = try(each.value.tags, null)
  check_existance            = var.check_existance
}
