# ── Container Registry Imports ─────────────────────────────────────────────────

variable "azure_container_registry_imports" {
  type = map(object({
    subscription_id     = optional(string)
    resource_group_name = string
    registry_name       = string
    source_registry_uri = string
    source_image        = string
    target_tags         = optional(list(string), null)
    mode                = optional(string, "Force")
  }))
  description = <<-EOT
    Map of images to import into Azure Container Registries.

    Example:
      azure_container_registry_imports = {
        arc_chart = {
          resource_group_name = "ref:azure_resource_groups.arc.resource_group_name"
          registry_name       = "ref:azure_container_registries.arc.registry_name"
          source_registry_uri = "mcr.microsoft.com"
          source_image        = "azurearck8s/batch1/stable/azure-arc-k8sagents:1.33.0"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_container_registry_imports = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_container_registry_imports, {}), var.azure_container_registry_imports)
  )
  _acri_ctx = provider::rest::merge_with_outputs(local.azure_container_registry_imports, module.azure_container_registry_imports)
}

module "azure_container_registry_imports" {
  source   = "./modules/azure/container_registry_import"
  for_each = local.azure_container_registry_imports

  depends_on = [module.azure_container_registries]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  registry_name       = each.value.registry_name
  source_registry_uri = each.value.source_registry_uri
  source_image        = each.value.source_image
  target_tags         = try(each.value.target_tags, null)
  mode                = try(each.value.mode, "Force")
}
