# ── Layer Context Accumulation ─────────────────────────────────────────────────
# Each resource file defines its own resolved config and context contribution
# (e.g. local._rg_ctx). This file accumulates them into per-layer contexts
# used by provider::rest::resolve_map() calls in each resource file.
#
# Layer ordering mirrors the implicit dependency graph:
#   L0  → subscriptions
#   L0b → + resource_groups
#   L0c → + network_managers     (IPAM chain — promoted to resolve before networking)
#   L0d → + ipam_pools           (depends on network_managers)
#   L0e → + ipam_static_cidrs    (single source of truth for CIDRs)
#   L1  → + VNets, vWANs, and all other resources that depend on L0e
#   L2  → + all resources that depend on L1
#   L3  → + all resources that depend on L2
#
# The actual YAML merge + ref resolution + context contribution per resource
# lives in each resource's own .tf file — this file is purely structural.

locals {
  # ── YAML config loading ────────────────────────────────────────────────
  _yaml_raw = var.config_file != null ? yamldecode(file(var.config_file)) : null

  # ── terraform_backend (READ-ONLY metadata) ─────────────────────────────
  # Parsed from YAML so preconditions can block managing backend resources.
  _terraform_backend = try(local._yaml_raw.terraform_backend, null)

  # ── Default location (YAML override or variable) ───────────────────────
  default_location = try(local._yaml_raw.default_location, var.default_location)

  # ── External references (static data, not managed by Terraform) ────────
  _externals = data.rest_validate_externals.this.result

  # ── Layer 0: subscriptions, billing associated tenants ─────────────────────
  _ctx_l0 = {
    azure_subscriptions              = local._sub_ctx
    azure_billing_associated_tenants = local._bat_ctx
    remote_states                    = merge(var.remote_states, local._remote_states_from_backend)
    externals                        = local._externals
    # Caller identity — populated by tf.sh or via TF_VAR_caller_object_id
    caller = {
      object_id       = var.caller_object_id
      subscription_id = var.subscription_id
    }
  }

  # ── Layer 0b: + resource_groups, tls_private_keys ─────────────────────
  _ctx_l0b = merge(local._ctx_l0, {
    azure_resource_groups = local._rg_ctx
    tls_private_keys      = local._tls_ctx
  })

  # ── Layer 0c: + network_managers (promoted — IPAM chain must resolve before networking)
  _ctx_l0c = merge(local._ctx_l0b, {
    azure_network_managers = local._nm_ctx
  })

  # ── Layer 0d: + ipam_pools (depends on network_managers from L0c)
  _ctx_l0d = merge(local._ctx_l0c, {
    azure_ipam_pools = local._ipam_pool_ctx
  })

  # ── Layer 0e: + ipam_static_cidrs (depends on ipam_pools from L0d)
  #    IPAM CIDRs are now the single source of truth for address prefixes.
  #    VNets and hubs at L1+ can ref:azure_ipam_static_cidrs.<key>.address_prefixes
  _ctx_l0e = merge(local._ctx_l0d, {
    azure_ipam_static_cidrs = local._ipam_sc_ctx
  })

  # ── Layer 1: + all L1 resources (starts from L0e — IPAM refs available) ─
  _ctx_l1 = merge(local._ctx_l0e, {
    azure_user_assigned_identities        = local._uai_ctx
    azure_key_vaults                      = local._kv_ctx
    azure_management_locks                = local._mlock_ctx
    azure_resource_provider_registrations = local._rpr_ctx
    azure_virtual_wans                    = local._vwan_ctx
    azure_firewall_policies               = local._fwp_ctx
    azure_virtual_networks                = local._vnet_ctx
    azure_public_ip_addresses             = local._pip_ctx
    azure_route_tables                    = local._rt_ctx
    azure_express_route_ports             = local._erp_ctx
    azure_ciam_directories                = local._ciam_ctx
    azure_redis_enterprise_clusters       = local._rec_ctx
    azure_email_communication_services    = local._ecs_ctx
    azure_app_service_domains             = local._asd_ctx
    # K8s L0 resources — available for cross-domain ref: resolution
    k8s_kind_clusters = local._k8s_kind_ctx
    # Entra ID L0 resources — available for cross-domain ref: resolution
    entraid_groups       = local._entraid_grp_ctx
    entraid_users        = local._entraid_usr_ctx
    entraid_applications = local._entraid_app_ctx
  })

  # ── Layer 2: + all L2 resources ────────────────────────────────────────
  _ctx_l2 = merge(local._ctx_l1, {
    azure_foundry_accounts                    = local._fa_ctx
    azure_arc_connected_clusters              = local._arc_cc_ctx
    azure_key_vault_keys                      = local._kvk_ctx
    azure_resource_provider_features          = local._rpf_ctx
    azure_virtual_hubs                        = local._vhub_ctx
    azure_virtual_network_gateways            = local._vngw_ctx
    azure_load_balancers                      = local._lb_ctx
    azure_network_interfaces                  = local._nic_ctx
    azure_express_route_circuits              = local._erc_ctx
    azure_redis_enterprise_databases          = local._red_ctx
    azure_private_dns_zones                   = local._pdz_ctx
    azure_dns_resolvers                       = local._dnspr_ctx
    azure_container_registries                = local._acr_ctx
    azure_email_communication_service_domains = local._ecsd_ctx
    azure_dns_zones                           = local._dz_ctx
  })

  # ── Layer 3: + resources that depend on L2 (virtual_hubs, storage, etc.)
  _ctx_l3 = merge(local._ctx_l2, {
    azure_role_assignments                    = local._ra_ctx
    azure_storage_accounts                    = local._sa_ctx
    azure_firewalls                           = local._afw_ctx
    azure_virtual_network_gateway_connections = local._conn_ctx
    azure_vpn_gateways                        = local._vpngw_ctx
    azure_virtual_hub_connections             = local._vhc_ctx
    azure_express_route_circuit_peerings      = local._ercp_ctx
    azure_container_registry_imports          = local._acri_ctx
    azure_arc_kubernetes_extensions           = local._arc_ext_ctx
    azure_managed_clusters                    = local._mc_ctx
    azure_virtual_network_peerings            = local._vnp_ctx
    azure_github_network_settings             = local._ghns_ctx
    azure_communication_services              = local._acs_ctx
    azure_dns_record_sets                     = local._drs_ctx
    azure_foundry_managed_networks            = local._fmn_ctx
    # azure_private_endpoints, azure_postgresql_flexible_servers,
    # azure_storage_account_blob_services, azure_storage_account_file_services,
    # azure_storage_account_management_policies, azure_storage_account_encryption_scopes,
    # azure_storage_account_local_users, azure_storage_account_object_replication_policies,
    # and azure_storage_account_inventory_policies resolve at L3 but are terminal
    # (nothing refs their outputs — do not add to context to avoid cycles)
  })

  # ── Layer 4: + Foundry deployments + Tier-A GitHub resources
  #    - azure_foundry_deployments     depend on azure_foundry_accounts (L2/L3)
  #    - github_runner_groups          depend on L3 github_network_settings
  #    - github_repositories           depend only on externals (resolved at L3)
  #    - github_organization_secrets   depend only on externals
  #    - github_organization_variables depend only on externals
  _ctx_l4 = merge(local._ctx_l3, {
    azure_foundry_deployments     = local._fd_ctx
    github_repositories           = local._ghrepo_ctx
    github_organization_secrets   = local._ghorgsec_ctx
    github_organization_variables = local._ghorgvar_ctx
    github_runner_groups          = local._ghrg_ctx
    # github_repository_secrets, github_repository_action_variables, and
    # github_hosted_runners all resolve at L4 but are terminal
    # (nothing refs their outputs).
  })

  # ── Layer 5: + Tier-B GitHub resources
  #    - github_environments depend on github_repositories (L4) for owner/repo refs
  #    github_environment_secrets and github_environment_variables resolve at L5
  #    but are terminal.
  _ctx_l5 = merge(local._ctx_l4, {
    github_environments = local._ghenv_ctx
  })
}
