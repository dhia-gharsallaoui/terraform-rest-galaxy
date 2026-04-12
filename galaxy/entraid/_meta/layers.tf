# ── Entra ID Layer Context Accumulation ────────────────────────────────────────
# Entra ID resources use the Microsoft Graph API and have their own layer
# hierarchy, starting from the Azure base context (local._ctx_l0b) so that
# ref: expressions can cross-reference Azure ARM resources.
#
# Layer ordering:
#   L0  → entraid_applications, entraid_groups, entraid_users, entraid_service_principals (no Entra ID cross-references)
#   L1  → entraid_group_members (← entraid_groups, entraid_users)
#   L2  → app_role_assignments, oauth2_permission_grants (← service_principals, groups)

locals {
  # ── Entra ID Layer 0: entraid_applications, entraid_groups, entraid_users, entraid_service_principals ──
  _entraid_ctx_l0 = merge(local._ctx_l0b, {
    entraid_applications       = local._entraid_app_ctx
    entraid_groups             = local._entraid_grp_ctx
    entraid_users              = local._entraid_usr_ctx
    entraid_service_principals = local._entraid_sp_ctx
  })

  # ── Entra ID Layer 1: entraid_group_members (← entraid_groups, entraid_users)
  _entraid_ctx_l1 = merge(local._entraid_ctx_l0, {
    entraid_group_members = local._entraid_gm_ctx
  })

  # ── Entra ID Layer 2: app_role_assignments, oauth2_permission_grants (← service_principals, groups)
  _entraid_ctx_l2 = merge(local._entraid_ctx_l1, {
    entraid_app_role_assignments     = local._entraid_ara_ctx
    entraid_oauth2_permission_grants = local._entraid_opg_ctx
  })
}
