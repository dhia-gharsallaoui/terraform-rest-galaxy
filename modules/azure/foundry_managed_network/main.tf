# Source: azure-rest-api-specs
#   spec_path  : cognitiveservices/resource-manager/Microsoft.CognitiveServices/preview
#   api_version: 2025-10-01-preview
#   stability  : preview
#   operation  : ManagedNetworks_CreateOrUpdate  (PUT, async — provisioningState polling)
#   delete     : NOT SUPPORTED independently (HTTP 405 Method Not Allowed)
#
# DELETION BEHAVIOUR: The managedNetworks child resource cannot be deleted independently.
# It is deleted automatically when the parent Foundry account is deleted.
# rest_operation is used instead of rest_resource so Terraform will NOT attempt a
# DELETE on terraform destroy (which would return 405). Delete the parent account.
#
# PREREQUISITE: The AI.ManagedVnetPreview feature flag must be registered:
#   azure_resource_provider_features:
#     foundry_managed_vnet:
#       provider_namespace: Microsoft.CognitiveServices
#       feature_name: AI.ManagedVnetPreview
#       state: Registered
# Approval takes several hours. Check status before applying.
#
# IRREVERSIBILITY: isolation_mode cannot be disabled after enabling.
# AllowInternetOutbound → AllowOnlyApprovedOutbound is also not supported.

locals {
  api_version          = "2025-10-01-preview"
  managed_network_name = "default"
  managed_network_path = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.CognitiveServices/accounts/${var.account_name}/managedNetworks/${local.managed_network_name}"

  # ── Typed outbound rules ──────────────────────────────────────────────────
  # Each rule type sets `destination` to a different shape (string vs object).
  # Terraform's type system rejects mixed-type ternaries in a single for
  # expression, so we use jsondecode(jsonencode(...)) to coerce each branch
  # to `any` before passing to merge(). This is intentional — not output access.
  outbound_rules_body = var.outbound_rules != null ? {
    for name, rule in var.outbound_rules : name => merge(
      { type = rule.type, category = rule.category },
      rule.type == "FQDN" ? jsondecode(jsonencode({
        destination = rule.fqdn_destination
      })) : {},
      rule.type == "PrivateEndpoint" ? jsondecode(jsonencode({
        destination = merge(
          { serviceResourceId = rule.private_endpoint_service_resource_id },
          rule.private_endpoint_subresource_target != null ? { subresourceTarget = rule.private_endpoint_subresource_target } : {},
          rule.private_endpoint_fqdns != null ? { fqdns = rule.private_endpoint_fqdns } : {},
        )
      })) : {},
      rule.type == "ServiceTag" ? jsondecode(jsonencode({
        destination = merge(
          rule.service_tag != null ? { serviceTag = rule.service_tag } : {},
          { action = rule.service_tag_action },
          rule.service_tag_protocol != null ? { protocol = rule.service_tag_protocol } : {},
          rule.service_tag_port_ranges != null ? { portRanges = rule.service_tag_port_ranges } : {},
          rule.service_tag_address_prefixes != null ? { addressPrefixes = rule.service_tag_address_prefixes } : {},
        )
      })) : {},
    )
  } : null

  managed_network = merge(
    { isolationMode = var.isolation_mode },
    { managedNetworkKind = var.managed_network_kind },
    var.firewall_sku != null ? { firewallSku = var.firewall_sku } : {},
    local.outbound_rules_body != null ? { outboundRules = local.outbound_rules_body } : {},
  )

  body = {
    properties = {
      managedNetwork = local.managed_network
    }
  }
}

resource "rest_operation" "foundry_managed_network" {
  path   = local.managed_network_path
  method = "PUT"

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.managedNetwork.isolationMode",
    "properties.managedNetwork.managedNetworkKind",
    "properties.managedNetwork.firewallSku",
    "properties.managedNetwork.status.status",
    "properties.provisioningState",
  ])

  # Managed network provisioning is slow (can take 10–20 minutes).
  poll = {
    status_locator    = "body.properties.provisioningState"
    default_delay_sec = 30
    status = {
      success = "Succeeded"
      pending = ["Creating", "Updating", "Accepted", "Provisioning", "Running"]
    }
  }
}
