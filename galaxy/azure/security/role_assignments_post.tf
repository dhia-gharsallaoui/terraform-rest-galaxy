# ── Role Assignments (Post-AKS) ──────────────────────────────────────────────
# Role assignments that target resources created at L3 (e.g. AKS clusters).
# These resolve at _ctx_l3 so they can reference azure_managed_clusters outputs.

variable "azure_role_assignments_post" {
  type = map(object({
    scope              = string
    role_definition_id = string
    principal_id       = string
    principal_type     = optional(string, "ServicePrincipal")
    description        = optional(string, null)
    condition          = optional(string, null)
    condition_version  = optional(string, null)
  }))
  description = <<-EOT
    Role assignments that depend on L3 resources (e.g. AKS clusters).
    Same schema as azure_role_assignments but resolved at _ctx_l3.
  EOT
  default     = {}
}

locals {
  azure_role_assignments_post = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_role_assignments_post, {}), var.azure_role_assignments_post)
  )
}

module "azure_role_assignments_post" {
  source   = "./modules/azure/role_assignment"
  for_each = local.azure_role_assignments_post

  depends_on = [module.azure_managed_clusters]

  subscription_id    = try(each.value.subscription_id, var.subscription_id)
  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id
  principal_id       = each.value.principal_id
  principal_type     = try(each.value.principal_type, "ServicePrincipal")
  description        = try(each.value.description, null)
  condition          = try(each.value.condition, null)
  condition_version  = try(each.value.condition_version, null)
  check_existance    = var.check_existance
}
