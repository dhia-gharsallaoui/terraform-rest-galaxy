# ── K8s Layer Context Accumulation ─────────────────────────────────────────────
# K8s resources have their own layer hierarchy, starting from the Azure base
# context so that ref: expressions can cross-reference Azure ARM and Entra ID
# resources (e.g. entraid_groups for RBAC bindings).
#
# Layer ordering:
#   L0   → k8s_kind_clusters (← azure context)
#   L0a  → k8s_namespaces, k8s_cluster_role_bindings (← k8s_kind_clusters)
#   L1   → k8s_service_accounts (← k8s_namespaces)
#   L1a  → k8s_deployments, k8s_config_maps (← k8s_service_accounts)
#   L2   → helm_releases (← k8s_kind_clusters, azure_arc_connected_clusters)

# ── K8s Token Resources ──────────────────────────────────────────────────────
# Creates a ServiceAccount + Bearer token per kind cluster using the
# kubeconfig with client cert auth. This runs inside the Terraform graph
# (after kind cluster creation) — no external two-phase apply needed.
resource "rest_token" "clusters" {
  for_each = module.k8s_kind_clusters

  kubeconfig = each.value.kubeconfig
}

locals {
  # Map cluster NAME → credentials from rest_token (kind clusters)
  _kind_cluster_creds_by_name = {
    for k, v in local.k8s_kind_clusters : v.name => {
      endpoint = rest_token.clusters[k].endpoint
      token    = rest_token.clusters[k].token
    }
  }

  # Map AKS cluster NAME → credentials from TF_VAR_k8s_aks_cluster_credentials
  # Populated by tf.sh when azure_managed_clusters are present in the config.
  _aks_cluster_creds_by_name = {
    for k, v in var.k8s_aks_cluster_credentials : k => {
      endpoint = v.endpoint
      token    = v.token
    }
  }

  # Merged map: kind + AKS clusters
  _k8s_cluster_creds_by_name = merge(
    local._kind_cluster_creds_by_name,
    local._aks_cluster_creds_by_name,
  )

  # Non-sensitive set of cluster names that have credentials available.
  # Used to filter for_each so K8s modules are skipped when AKS doesn't exist yet.
  _k8s_available_clusters = nonsensitive(toset(keys(local._k8s_cluster_creds_by_name)))

  # ── K8s Layer 0: kind clusters ───────────────────────────────────────────
  # Merges from Azure L3 context so K8s refs can access managed_clusters,
  # postgresql_flexible_servers, etc.
  _k8s_ctx_l0 = merge(local._ctx_l3, {
    azure_postgresql_flexible_servers = local._pg_ctx
    k8s_kind_clusters                 = local._k8s_kind_ctx
  })

  # ── K8s Layer 0a: namespaces + CRBs (resolve context for service accounts)
  _k8s_ctx_l0a = merge(local._k8s_ctx_l0, {
    k8s_namespaces            = local._k8s_ns_ctx
    k8s_cluster_role_bindings = local._k8s_crb_ctx
  })

  # ── K8s Layer 1: service accounts (depend on namespaces, resolve context for deployments)
  _k8s_ctx_l1 = merge(local._k8s_ctx_l0a, {
    k8s_service_accounts = local._k8s_sa_ctx
  })

  # ── K8s Layer 2: helm_releases (depend on arc connected clusters) ──────
  _k8s_ctx_l2 = merge(local._k8s_ctx_l1, {
    azure_arc_connected_clusters = local._arc_cc_ctx
    azure_container_registries   = local._acr_ctx
  })
}
