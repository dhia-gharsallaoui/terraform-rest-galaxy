# ── Azure AI Foundry Deployments ──────────────────────────────────────────────
# Microsoft.CognitiveServices/accounts/deployments
# API: 2025-09-01 (stable)
#
# Model availability is validated at plan time via:
#   GET /subscriptions/{id}/providers/Microsoft.CognitiveServices/locations/{location}/models

variable "azure_foundry_deployments" {
  type = map(object({
    # ── Scope ─────────────────────────────────────────────────────────────────
    subscription_id     = optional(string, null)
    resource_group_name = string
    account_name        = string
    location            = string
    deployment_name     = string

    # ── Model ─────────────────────────────────────────────────────────────────
    model_format         = string
    model_name           = string
    model_version        = optional(string, null)
    model_publisher      = optional(string, null)
    model_source         = optional(string, null)
    model_source_account = optional(string, null)

    # ── SKU ───────────────────────────────────────────────────────────────────
    sku_name     = string
    sku_capacity = optional(number, null)

    # ── Upgrade & Policy ──────────────────────────────────────────────────────
    version_upgrade_option = optional(string, "OnceNewDefaultVersionAvailable")
    rai_policy_name        = optional(string, null)

    # ── Scale & Capacity ──────────────────────────────────────────────────────
    scale_type                            = optional(string, null)
    scale_capacity                        = optional(number, null)
    capacity_settings_designated_capacity = optional(number, null)
    capacity_settings_priority            = optional(number, null)

    # ── Advanced ──────────────────────────────────────────────────────────────
    parent_deployment_name    = optional(string, null)
    spillover_deployment_name = optional(string, null)

    # ── Tags ──────────────────────────────────────────────────────────────────
    tags = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Azure AI Foundry model deployments to create. Each map key is the for_each
    identifier. Deployments must reference an existing Foundry account.

    A plan-time precondition validates that model_name is available in the target
    location before applying. If the model is not available, terraform plan fails
    with a CLI command to list available models.

    Example (GPT-4o GlobalStandard):
      azure_foundry_deployments = {
        gpt4o = {
          resource_group_name    = "rg-foundry"
          account_name           = "my-foundry"
          location               = "francecentral"
          deployment_name        = "gpt-4o"
          model_format           = "OpenAI"
          model_name             = "gpt-4o"
          model_version          = "2024-08-06"
          sku_name               = "GlobalStandard"
          sku_capacity           = 100
          version_upgrade_option = "OnceNewDefaultVersionAvailable"
        }
      }

    Example (embeddings + spillover):
      azure_foundry_deployments = {
        embeddings = {
          resource_group_name       = "rg-foundry"
          account_name              = "my-foundry"
          location                  = "francecentral"
          deployment_name           = "text-embedding-3-large"
          model_format              = "OpenAI"
          model_name                = "text-embedding-3-large"
          sku_name                  = "Standard"
          sku_capacity              = 50
          version_upgrade_option    = "NoAutoUpgrade"
          spillover_deployment_name = "text-embedding-3-large-fallback"
        }
      }
  EOT
  default     = {}
}

locals {
  azure_foundry_deployments = provider::rest::resolve_map(
    local._ctx_l3,
    merge(try(local._yaml_raw.azure_foundry_deployments, {}), var.azure_foundry_deployments)
  )
  _fd_ctx = provider::rest::merge_with_outputs(local.azure_foundry_deployments, module.azure_foundry_deployments)
}

module "azure_foundry_deployments" {
  source   = "./modules/azure/foundry_deployment"
  for_each = local.azure_foundry_deployments

  depends_on = [module.azure_foundry_accounts]

  subscription_id     = try(each.value.subscription_id, null) != null ? each.value.subscription_id : var.subscription_id
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  location            = each.value.location
  deployment_name     = each.value.deployment_name

  model_format         = each.value.model_format
  model_name           = each.value.model_name
  model_version        = try(each.value.model_version, null)
  model_publisher      = try(each.value.model_publisher, null)
  model_source         = try(each.value.model_source, null)
  model_source_account = try(each.value.model_source_account, null)

  sku_name     = each.value.sku_name
  sku_capacity = try(each.value.sku_capacity, null)

  version_upgrade_option = try(each.value.version_upgrade_option, "OnceNewDefaultVersionAvailable")
  rai_policy_name        = try(each.value.rai_policy_name, null)

  scale_type     = try(each.value.scale_type, null)
  scale_capacity = try(each.value.scale_capacity, null)

  capacity_settings_designated_capacity = try(each.value.capacity_settings_designated_capacity, null)
  capacity_settings_priority            = try(each.value.capacity_settings_priority, null)

  parent_deployment_name    = try(each.value.parent_deployment_name, null)
  spillover_deployment_name = try(each.value.spillover_deployment_name, null)

  tags = try(each.value.tags, null)

  check_existance = var.check_existance
}
