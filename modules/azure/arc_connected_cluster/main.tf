# Source: azure-rest-api-specs
#   spec_path  : hybridkubernetes/resource-manager/Microsoft.Kubernetes
#   api_version: 2024-01-01
#   operation  : ConnectedCluster_Create  (PUT, async — azure-async-operation)
#   delete     : ConnectedCluster_Delete  (DELETE, async — location)

locals {
  api_version = "2024-01-01"
  cc_path     = "/subscriptions/${var.subscription_id}/resourcegroups/${var.resource_group_name}/providers/Microsoft.Kubernetes/connectedClusters/${var.cluster_name}"

  # NOTE: aadProfile cannot be set during connectedCluster creation (PUT).
  # The Azure API returns error 1000 for any PUT body that includes aadProfile,
  # regardless of API version (tested stable 2024-01-01 through 2025-12-01-preview).
  # AAD configuration is set by the Arc agent after it connects to the cluster.

  # Arc agent profile — omit entirely when not provided
  arc_agent_profile = var.arc_agent_profile != null ? merge(
    var.arc_agent_profile.desired_agent_version != null ? { desiredAgentVersion = var.arc_agent_profile.desired_agent_version } : {},
    var.arc_agent_profile.agent_auto_upgrade != null ? { agentAutoUpgrade = var.arc_agent_profile.agent_auto_upgrade } : {},
  ) : null

  # properties sub-object — only include explicitly set values
  properties = merge(
    { agentPublicKeyCertificate = var.agent_public_key_certificate },
    var.distribution != null ? { distribution = var.distribution } : {},
    var.distribution_version != null ? { distributionVersion = var.distribution_version } : {},
    var.infrastructure != null ? { infrastructure = var.infrastructure } : {},
    var.private_link_state != null ? { privateLinkState = var.private_link_state } : {},
    var.private_link_scope_resource_id != null ? { privateLinkScopeResourceId = var.private_link_scope_resource_id } : {},
    var.azure_hybrid_benefit != null ? { azureHybridBenefit = var.azure_hybrid_benefit } : {},
    local.arc_agent_profile != null ? { arcAgentProfile = local.arc_agent_profile } : {},
  )

  body = merge(
    {
      location   = var.location
      identity   = { type = var.identity_type }
      properties = local.properties
    },
    var.tags != null ? { tags = var.tags } : {},
    var.kind != null ? { kind = var.kind } : {},
  )
}

# ── Resource provider registration check ──────────────────────────────────────
data "rest_resource" "provider_check" {
  id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Kubernetes"

  query = {
    api-version = ["2025-04-01"]
  }

  output_attrs = toset(["registrationState"])
}

resource "rest_resource" "connected_cluster" {
  path            = local.cc_path
  create_method   = "PUT"
  update_method   = "PUT"
  check_existance = var.check_existance
  auth_ref        = var.auth_ref

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.provisioningState",
    "properties.kubernetesVersion",
    "properties.totalNodeCount",
    "properties.agentVersion",
    "properties.connectivityStatus",
    "identity.principalId",
    "identity.tenantId",
    "type",
    "tags",
  ])

  lifecycle {
    precondition {
      condition     = data.rest_resource.provider_check.output.registrationState == "Registered"
      error_message = "Resource provider Microsoft.Kubernetes is not registered on subscription ${var.subscription_id}. Add to your config YAML:\n\n  azure_resource_provider_registrations:\n    kubernetes:\n      resource_provider_namespace: Microsoft.Kubernetes"
    }
  }

  # PUT is async — azure-async-operation polling.
  # Poll the resource's own path via provisioningState.
  poll_create = {
    status_locator    = "body.properties.provisioningState"
    default_delay_sec = 10
    status = {
      success = "Succeeded"
      pending = ["Provisioning", "Updating", "Accepted"]
    }
  }

  # PUT update is async — same polling as create.
  poll_update = {
    status_locator    = "body.properties.provisioningState"
    default_delay_sec = 10
    status = {
      success = "Succeeded"
      pending = ["Provisioning", "Updating", "Accepted"]
    }
  }

  # DELETE is async — location header polling.
  poll_delete = {
    status_locator    = "code"
    default_delay_sec = 10
    status = {
      success = "404"
      pending = ["202", "200"]
    }
  }
}

# ── Wait for Arc agent connectivity ──────────────────────────────────────────
# After the ARM resource is provisioned (provisioningState=Succeeded), the Arc
# agent still needs time to bootstrap on the cluster and call back to Azure.
# This operation polls the cluster until connectivityStatus becomes "Connected".
resource "rest_operation" "wait_for_connection" {
  count  = var.wait_for_connection ? 1 : 0
  path   = local.cc_path
  method = "GET"

  query = {
    api-version = [local.api_version]
  }

  poll = {
    status_locator    = "body.properties.connectivityStatus"
    default_delay_sec = 15
    status = {
      success = "Connected"
      pending = ["Connecting"]
    }
  }

  output_attrs = toset([
    "properties.connectivityStatus",
    "properties.agentVersion",
    "properties.kubernetesVersion",
    "properties.totalNodeCount",
  ])

  depends_on = [rest_resource.connected_cluster]
}
