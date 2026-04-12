# ── Managed Clusters (AKS) ────────────────────────────────────────────────────

variable "azure_managed_clusters" {
  type = map(object({
    subscription_id                     = string
    resource_group_name                 = string
    cluster_name                        = optional(string, null)
    location                            = optional(string, null)
    sku_name                            = optional(string, "Automatic")
    sku_tier                            = optional(string, "Standard")
    identity_type                       = optional(string, "SystemAssigned")
    identity_user_assigned_identity_ids = optional(list(string), null)
    kubernetes_version                  = optional(string, null)
    dns_prefix                          = optional(string, null)
    node_resource_group                 = optional(string, null)
    network_plugin                      = optional(string, "azure")
    network_plugin_mode                 = optional(string, "overlay")
    network_dataplane                   = optional(string, "cilium")
    network_policy                      = optional(string, "cilium")
    service_cidr                        = optional(string, null)
    dns_service_ip                      = optional(string, null)
    pod_cidr                            = optional(string, null)
    outbound_type                       = optional(string, null)
    load_balancer_sku                   = optional(string, null)
    enable_private_cluster              = optional(bool, false)
    private_dns_zone                    = optional(string, null)
    enable_private_cluster_public_fqdn  = optional(bool, null)
    disable_run_command                 = optional(bool, null)
    authorized_ip_ranges                = optional(list(string), null)
    enable_vnet_integration             = optional(bool, null)
    api_server_subnet_id                = optional(string, null)
    aad_managed                         = optional(bool, true)
    aad_enable_azure_rbac               = optional(bool, true)
    aad_admin_group_object_ids          = optional(list(string), null)
    aad_tenant_id                       = optional(string, null)
    enable_workload_identity            = optional(bool, true)
    enable_defender                     = optional(bool, false)
    defender_log_analytics_workspace_id = optional(string, null)
    enable_image_cleaner                = optional(bool, null)
    image_cleaner_interval_hours        = optional(number, null)
    enable_oidc_issuer                  = optional(bool, true)
    upgrade_channel                     = optional(string, "stable")
    node_os_upgrade_channel             = optional(string, null)
    node_provisioning_mode              = optional(string, null)
    agent_pool_profiles = optional(list(object({
      name                  = string
      count                 = optional(number)
      vm_size               = optional(string)
      os_disk_size_gb       = optional(number)
      os_disk_type          = optional(string)
      os_type               = optional(string)
      os_sku                = optional(string)
      mode                  = optional(string, "System")
      min_count             = optional(number)
      max_count             = optional(number)
      enable_auto_scaling   = optional(bool)
      max_pods              = optional(number)
      vnet_subnet_id        = optional(string)
      availability_zones    = optional(list(string))
      node_labels           = optional(map(string))
      node_taints           = optional(list(string))
      enable_node_public_ip = optional(bool)
      type                  = optional(string, "VirtualMachineScaleSets")
      scale_set_priority    = optional(string)
      orchestrator_version  = optional(string)
      tags                  = optional(map(string))
    })), null)
    disable_local_accounts = optional(bool, true)
    enable_rbac            = optional(bool, true)
    public_network_access  = optional(string, null)
    tags                   = optional(map(string), null)
  }))
  description = "Map of AKS managed clusters to create."
  default     = {}
}

locals {
  azure_managed_clusters = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_managed_clusters, {}), var.azure_managed_clusters)
  )
  _mc_ctx = provider::rest::merge_with_outputs(local.azure_managed_clusters, module.azure_managed_clusters)
}

module "azure_managed_clusters" {
  source   = "./modules/azure/managed_cluster"
  for_each = local.azure_managed_clusters

  depends_on = [module.azure_virtual_networks, module.azure_user_assigned_identities, module.azure_private_dns_zones, module.azure_role_assignments]

  subscription_id                     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name                 = each.value.resource_group_name
  cluster_name                        = try(each.value.cluster_name, null) != null ? each.value.cluster_name : each.key
  location                            = try(each.value.location != null ? each.value.location : local.default_location, local.default_location)
  sku_name                            = try(each.value.sku_name, "Automatic")
  sku_tier                            = try(each.value.sku_tier, "Standard")
  identity_type                       = try(each.value.identity_type, "SystemAssigned")
  identity_user_assigned_identity_ids = try(each.value.identity_user_assigned_identity_ids, null)
  kubernetes_version                  = try(each.value.kubernetes_version, null)
  dns_prefix                          = try(each.value.dns_prefix, null)
  node_resource_group                 = try(each.value.node_resource_group, null)
  network_plugin                      = try(each.value.network_plugin, "azure")
  network_plugin_mode                 = try(each.value.network_plugin_mode, "overlay")
  network_dataplane                   = try(each.value.network_dataplane, "cilium")
  network_policy                      = try(each.value.network_policy, "cilium")
  service_cidr                        = try(each.value.service_cidr, null)
  dns_service_ip                      = try(each.value.dns_service_ip, null)
  pod_cidr                            = try(each.value.pod_cidr, null)
  outbound_type                       = try(each.value.outbound_type, null)
  load_balancer_sku                   = try(each.value.load_balancer_sku, null)
  enable_private_cluster              = try(each.value.enable_private_cluster, false)
  private_dns_zone                    = try(each.value.private_dns_zone, null)
  enable_private_cluster_public_fqdn  = try(each.value.enable_private_cluster_public_fqdn, null)
  disable_run_command                 = try(each.value.disable_run_command, null)
  authorized_ip_ranges                = try(each.value.authorized_ip_ranges, null)
  enable_vnet_integration             = try(each.value.enable_vnet_integration, null)
  api_server_subnet_id                = try(each.value.api_server_subnet_id, null)
  aad_managed                         = try(each.value.aad_managed, true)
  aad_enable_azure_rbac               = try(each.value.aad_enable_azure_rbac, true)
  aad_admin_group_object_ids          = try(each.value.aad_admin_group_object_ids, null)
  aad_tenant_id                       = try(each.value.aad_tenant_id, null)
  enable_workload_identity            = try(each.value.enable_workload_identity, true)
  enable_defender                     = try(each.value.enable_defender, false)
  defender_log_analytics_workspace_id = try(each.value.defender_log_analytics_workspace_id, null)
  enable_image_cleaner                = try(each.value.enable_image_cleaner, null)
  image_cleaner_interval_hours        = try(each.value.image_cleaner_interval_hours, null)
  enable_oidc_issuer                  = try(each.value.enable_oidc_issuer, true)
  upgrade_channel                     = try(each.value.upgrade_channel, "stable")
  node_os_upgrade_channel             = try(each.value.node_os_upgrade_channel, null)
  node_provisioning_mode              = try(each.value.node_provisioning_mode, null)
  agent_pool_profiles                 = try(each.value.agent_pool_profiles, null)
  disable_local_accounts              = try(each.value.disable_local_accounts, true)
  enable_rbac                         = try(each.value.enable_rbac, true)
  public_network_access               = try(each.value.public_network_access, null)
  tags                                = try(each.value.tags, null)
  check_existance                     = var.check_existance
}
