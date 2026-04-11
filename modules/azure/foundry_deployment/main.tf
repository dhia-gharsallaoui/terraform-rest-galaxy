# Source: azure-rest-api-specs
#   spec_path  : cognitiveservices/resource-manager/Microsoft.CognitiveServices/stable
#   api_version: 2025-09-01
#   stability  : stable
#   operation  : Deployments_CreateOrUpdate  (PUT, async — provisioningState polling)
#   delete     : Deployments_Delete          (DELETE, async)
#
# Model availability is validated at plan time via a data source against:
#   GET /subscriptions/{id}/providers/Microsoft.CognitiveServices/locations/{location}/models
# This ensures model_name is available in the target region before apply.

locals {
  api_version     = "2025-09-01"
  deployment_path = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.CognitiveServices/accounts/${var.account_name}/deployments/${var.deployment_name}"

  # ── Model ────────────────────────────────────────────────────────────────────
  model = merge(
    { format = var.model_format },
    { name = var.model_name },
    var.model_version != null ? { version = var.model_version } : {},
    var.model_publisher != null ? { publisher = var.model_publisher } : {},
    var.model_source != null ? { source = var.model_source } : {},
    var.model_source_account != null ? { sourceAccount = var.model_source_account } : {},
  )

  # ── SKU ─────────────────────────────────────────────────────────────────────
  sku = merge(
    { name = var.sku_name },
    var.sku_capacity != null ? { capacity = var.sku_capacity } : {},
  )

  # ── Scale Settings ───────────────────────────────────────────────────────────
  scale_settings = var.scale_type != null ? merge(
    { scaleType = var.scale_type },
    var.scale_capacity != null ? { capacity = var.scale_capacity } : {},
  ) : null

  # ── Capacity Settings ────────────────────────────────────────────────────────
  capacity_settings = (
    var.capacity_settings_designated_capacity != null ||
    var.capacity_settings_priority != null
    ) ? merge(
    var.capacity_settings_designated_capacity != null ? { designatedCapacity = var.capacity_settings_designated_capacity } : {},
    var.capacity_settings_priority != null ? { priority = var.capacity_settings_priority } : {},
  ) : null

  # ── Properties ───────────────────────────────────────────────────────────────
  properties = merge(
    { model = local.model },
    { versionUpgradeOption = var.version_upgrade_option },
    var.rai_policy_name != null ? { raiPolicyName = var.rai_policy_name } : {},
    var.parent_deployment_name != null ? { parentDeploymentName = var.parent_deployment_name } : {},
    var.spillover_deployment_name != null ? { spilloverDeploymentName = var.spillover_deployment_name } : {},
    local.scale_settings != null ? { scaleSettings = local.scale_settings } : {},
    local.capacity_settings != null ? { capacitySettings = local.capacity_settings } : {},
  )

  # ── Full body ─────────────────────────────────────────────────────────────────
  body = merge(
    { properties = local.properties },
    { sku = local.sku },
    var.tags != null ? { tags = var.tags } : {},
  )
}

# ── Model availability data source ───────────────────────────────────────────
# GET /subscriptions/{id}/providers/Microsoft.CognitiveServices/locations/{location}/models
# Validates at plan time that the requested model is available in the target region.

data "rest_resource" "available_models" {
  id = "/subscriptions/${var.subscription_id}/providers/Microsoft.CognitiveServices/locations/${var.location}/models"

  query = {
    api-version = ["2025-06-01"]
  }

  output_attrs = toset(["value.#.model.name"])
}

# ── Deployment ────────────────────────────────────────────────────────────────

resource "rest_resource" "foundry_deployment" {
  path            = local.deployment_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.provisioningState",
    "properties.model.name",
    "properties.model.format",
    "properties.model.version",
    "properties.versionUpgradeOption",
    "properties.rateLimits",
    "sku.name",
    "sku.capacity",
  ])

  lifecycle {
    precondition {
      # FilterAttrsInJSON preserves the JSON structure: output_attrs = ["value.#.model.name"]
      # filters the response to {"value": [{"model": {"name": "..."}}, ...]}.
      # Access via output.value (a list of objects) and extract names with a for expression.
      condition = contains(
        [for item in data.rest_resource.available_models.output.value : item.model.name],
        var.model_name
      )
      error_message = <<-EOT
        Model '${var.model_name}' is not available in location '${var.location}'.
        Check available models with:
          az rest --method GET \
            --url 'https://management.azure.com/subscriptions/${var.subscription_id}/providers/Microsoft.CognitiveServices/locations/${var.location}/models?api-version=2025-06-01' \
            --query 'value[].model.name' -o tsv
      EOT
    }
  }

  # Deployment provisioning is async — poll on provisioningState.
  poll_create = {
    status_locator    = "body.properties.provisioningState"
    default_delay_sec = 10
    status = {
      success = "Succeeded"
      pending = ["Creating", "Updating", "Accepted", "Running", "Scaling"]
    }
  }

  poll_update = {
    status_locator    = "body.properties.provisioningState"
    default_delay_sec = 10
    status = {
      success = "Succeeded"
      pending = ["Creating", "Updating", "Accepted", "Running", "Scaling"]
    }
  }

  # DELETE is async — poll until resource returns 404.
  poll_delete = {
    status_locator    = "code"
    default_delay_sec = 10
    status = {
      success = "404"
      pending = ["202", "200"]
    }
  }
}
