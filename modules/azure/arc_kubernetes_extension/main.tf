# Source: azure-rest-api-specs
#   spec_path  : kubernetesconfiguration/resource-manager/Microsoft.KubernetesConfiguration/Extensions
#   api_version: 2025-03-01
#   operation  : Extensions_Create  (PUT, async — azure-async-operation)
#   delete     : Extensions_Delete  (DELETE, async — azure-async-operation)

locals {
  api_version = "2025-03-01"
  ext_path    = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/${var.cluster_rp}/${var.cluster_resource_name}/${var.cluster_name}/providers/Microsoft.KubernetesConfiguration/extensions/${var.extension_name}"

  # ── Known Arc extension registry ──────────────────────────────────────────
  # Maps extension_type → list of supported CPU architectures.
  # Extensions NOT listed here are assumed to support all architectures.
  # Source: tested against Azure Arc Kubernetes marketplace, April 2026.
  extension_registry = {
    "microsoft.monitor.pipelinecontroller" = ["amd64"]
    "microsoft.azuremonitor.containers"    = ["amd64", "arm64"]
    "microsoft.flux"                       = ["amd64", "arm64"]
    "microsoft.dapr"                       = ["amd64", "arm64"]
    "microsoft.azuredefender.kubernetes"   = ["amd64"]
    "microsoft.policyinsights"             = ["amd64", "arm64"]
    "microsoft.openservicemesh"            = ["amd64"]
    "microsoft.azurekeyvaulssecretsstore"  = ["amd64", "arm64"]
    "microsoft.arc.containerstorage"       = ["amd64"]
    "microsoft.web.appservice"             = ["amd64"]
    "microsoft.arcdataservices"            = ["amd64"]
  }

  # Look up the extension type (case-insensitive) in the registry
  _ext_type_lower     = lower(var.extension_type)
  _supported_archs    = try(local.extension_registry[local._ext_type_lower], null)
  _arch_check_applies = local._supported_archs != null && var.cluster_node_architecture != null
  _arch_is_supported  = local._arch_check_applies ? contains(local._supported_archs, var.cluster_node_architecture) : true

  # scope sub-object
  scope = var.scope != null ? merge(
    var.scope.cluster != null ? {
      cluster = merge(
        var.scope.cluster.release_namespace != null ? { releaseNamespace = var.scope.cluster.release_namespace } : {},
      )
    } : {},
    var.scope.namespace != null ? {
      namespace = merge(
        var.scope.namespace.target_namespace != null ? { targetNamespace = var.scope.namespace.target_namespace } : {},
      )
    } : {},
  ) : null

  # properties sub-object — only include explicitly set values
  properties = merge(
    { extensionType = var.extension_type },
    { autoUpgradeMinorVersion = var.auto_upgrade_minor_version },
    var.release_train != null ? { releaseTrain = var.release_train } : {},
    var.version_pin != null ? { version = var.version_pin } : {},
    local.scope != null ? { scope = local.scope } : {},
    var.configuration_settings != null ? { configurationSettings = var.configuration_settings } : {},
    var.configuration_protected_settings != null ? { configurationProtectedSettings = var.configuration_protected_settings } : {},
  )

  body = merge(
    { properties = local.properties },
    var.identity_type != null ? { identity = { type = var.identity_type } } : {},
    var.plan != null ? {
      plan = {
        name      = var.plan.name
        publisher = var.plan.publisher
        product   = var.plan.product
      }
    } : {},
  )
}

# ── Resource provider registration check ──────────────────────────────────────
data "rest_resource" "provider_check" {
  id = "/subscriptions/${var.subscription_id}/providers/Microsoft.KubernetesConfiguration"

  query = {
    api-version = ["2025-04-01"]
  }

  output_attrs = toset(["registrationState"])
}

# ── Connected cluster status check ───────────────────────────────────────────
data "rest_resource" "cluster_check" {
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/${var.cluster_rp}/${var.cluster_resource_name}/${var.cluster_name}"

  query = {
    api-version = ["2024-01-01"]
  }

  output_attrs = toset(["properties.connectivityStatus", "properties.totalNodeCount"])
}

resource "rest_resource" "extension" {
  path             = local.ext_path
  create_method    = "PUT"
  update_method    = "PUT"
  check_existance  = var.check_existance
  auth_ref         = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  lifecycle {
    precondition {
      condition     = data.rest_resource.provider_check.output.registrationState == "Registered"
      error_message = "Resource provider Microsoft.KubernetesConfiguration is not registered on subscription ${var.subscription_id}. Add to your config YAML:\n\n  azure_resource_provider_registrations:\n    kubernetes_configuration:\n      resource_provider_namespace: Microsoft.KubernetesConfiguration"
    }
    precondition {
      condition     = data.rest_resource.cluster_check.output.properties.connectivityStatus == "Connected"
      error_message = "Cluster ${var.cluster_name} is not connected (status: ${try(data.rest_resource.cluster_check.output.properties.connectivityStatus, "unknown")}). The cluster must be in Connected state before installing extensions."
    }
    precondition {
      condition     = local._arch_is_supported
      error_message = "Extension ${var.extension_name} (${var.extension_type}) supports architectures [${try(join(", ", local._supported_archs), "?")}], but cluster ${var.cluster_name} has ${coalesce(var.cluster_node_architecture, "unknown")} nodes. The extension will fail to schedule pods on this cluster."
    }
  }

  output_attrs = toset([
    "properties.provisioningState",
    "properties.currentVersion",
    "properties.extensionType",
    "properties.isSystemExtension",
    "properties.extensionState",
    "identity.principalId",
    "identity.tenantId",
  ])

  # PUT is async — azure-async-operation polling.
  poll_create = {
    status_locator    = "body.properties.provisioningState"
    default_delay_sec = 15
    status = {
      success = "Succeeded"
      pending = ["Creating", "Updating", "Accepted"]
    }
  }

  poll_update = {
    status_locator    = "body.properties.provisioningState"
    default_delay_sec = 15
    status = {
      success = "Succeeded"
      pending = ["Creating", "Updating", "Accepted"]
    }
  }

  # DELETE is async — azure-async-operation polling.
  poll_delete = {
    status_locator    = "code"
    default_delay_sec = 15
    status = {
      success = "404"
      pending = ["202", "200"]
    }
  }
}
