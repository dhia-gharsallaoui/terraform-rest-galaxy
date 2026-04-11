# Source: azure-rest-api-specs
#   spec_path  : cognitiveservices/resource-manager/Microsoft.CognitiveServices/preview
#   api_version: 2025-10-01-preview
#   stability  : preview
#   operation  : Accounts_Create  (PUT, async — provisioningState polling)
#   delete     : Accounts_Delete  (DELETE, async)
#
# NOTE: This module targets Microsoft.CognitiveServices/accounts with kind=AIFoundry.
# This is Azure AI Foundry v2 (the new Microsoft Foundry portal at ai.azure.com).
# It is NOT Microsoft.MachineLearningServices/workspaces (the old Azure AI Studio / Hub).
#
# Security defaults are set for SOC2/regulated-industry compliance:
#   - public_network_access = "Disabled"
#   - disable_local_auth    = true
#   - network_acls_default_action = "Deny"

locals {
  api_version  = "2025-10-01-preview"
  account_path = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.CognitiveServices/accounts/${var.account_name}"

  # ── Identity ────────────────────────────────────────────────────────────────
  identity = var.identity_type != null ? merge(
    { type = var.identity_type },
    var.identity_user_assigned_identity_ids != null ? {
      userAssignedIdentities = { for id in var.identity_user_assigned_identity_ids : id => {} }
    } : {},
  ) : null

  # ── Network ACLs ────────────────────────────────────────────────────────────
  network_acls = merge(
    { defaultAction = var.network_acls_default_action },
    var.network_acls_bypass != null ? { bypass = var.network_acls_bypass } : {},
    var.network_acls_ip_rules != null ? {
      ipRules = [for ip in var.network_acls_ip_rules : { value = ip }]
    } : {},
    var.network_acls_virtual_network_rules != null ? {
      virtualNetworkRules = [for r in var.network_acls_virtual_network_rules : merge(
        { id = r.id },
        r.ignore_missing_vnet_service_endpoint ? { ignoreMissingVnetServiceEndpoint = true } : {},
      )]
    } : {},
  )

  # ── Encryption (CMK) ────────────────────────────────────────────────────────
  encryption = var.encryption_key_source != null ? merge(
    { keySource = var.encryption_key_source },
    var.encryption_key_source == "Microsoft.KeyVault" ? {
      keyVaultProperties = merge(
        var.encryption_key_vault_uri != null ? { keyVaultUri = var.encryption_key_vault_uri } : {},
        var.encryption_key_name != null ? { keyName = var.encryption_key_name } : {},
        var.encryption_key_version != null ? { keyVersion = var.encryption_key_version } : {},
        var.encryption_identity_client_id != null ? { identityClientId = var.encryption_identity_client_id } : {},
      )
    } : {},
  ) : null

  # ── Network Injections ───────────────────────────────────────────────────────
  network_injections = var.network_injections != null ? [
    for ni in var.network_injections : merge(
      { scenario = ni.scenario },
      { subnetArmId = ni.subnet_arm_id },
      ni.use_microsoft_managed_network ? { useMicrosoftManagedNetwork = true } : {},
    )
  ] : null

  # ── User-Owned Storage ───────────────────────────────────────────────────────
  user_owned_storage = var.user_owned_storage != null ? [
    for s in var.user_owned_storage : merge(
      { resourceId = s.resource_id },
      s.identity_client_id != null ? { identityClientId = s.identity_client_id } : {},
    )
  ] : null

  # ── RAI Monitor Config ───────────────────────────────────────────────────────
  rai_monitor_config = var.rai_monitor_config_storage_resource_id != null ? merge(
    { adxStorageResourceId = var.rai_monitor_config_storage_resource_id },
    var.rai_monitor_config_identity_client_id != null ? { identityClientId = var.rai_monitor_config_identity_client_id } : {},
  ) : null

  # ── AML Workspace ────────────────────────────────────────────────────────────
  aml_workspace = var.aml_workspace_resource_id != null ? merge(
    { resourceId = var.aml_workspace_resource_id },
    var.aml_workspace_identity_client_id != null ? { identityClientId = var.aml_workspace_identity_client_id } : {},
  ) : null

  # ── Properties ───────────────────────────────────────────────────────────────
  properties = merge(
    { publicNetworkAccess = var.public_network_access },
    { disableLocalAuth = var.disable_local_auth },
    { networkAcls = local.network_acls },
    var.allow_project_management != null ? { allowProjectManagement = var.allow_project_management } : {},
    var.custom_sub_domain_name != null ? { customSubDomainName = var.custom_sub_domain_name } : {},
    var.restrict_outbound_network_access != null ? { restrictOutboundNetworkAccess = var.restrict_outbound_network_access } : {},
    var.allowed_fqdn_list != null ? { allowedFqdnList = var.allowed_fqdn_list } : {},
    var.stored_completions_disabled != null ? { storedCompletionsDisabled = var.stored_completions_disabled } : {},
    var.dynamic_throttling_enabled != null ? { dynamicThrottlingEnabled = var.dynamic_throttling_enabled } : {},
    var.associated_projects != null ? { associatedProjects = var.associated_projects } : {},
    var.default_project != null ? { defaultProject = var.default_project } : {},
    var.restore != null ? { restore = var.restore } : {},
    local.encryption != null ? { encryption = local.encryption } : {},
    local.network_injections != null ? { networkInjections = local.network_injections } : {},
    local.user_owned_storage != null ? { userOwnedStorage = local.user_owned_storage } : {},
    local.rai_monitor_config != null ? { raiMonitorConfig = local.rai_monitor_config } : {},
    local.aml_workspace != null ? { amlWorkspace = local.aml_workspace } : {},
  )

  # ── SKU ──────────────────────────────────────────────────────────────────────
  sku = merge(
    { name = var.sku_name },
    var.sku_capacity != null ? { capacity = var.sku_capacity } : {},
    var.sku_tier != null ? { tier = var.sku_tier } : {},
  )

  # ── Full body ─────────────────────────────────────────────────────────────────
  body = merge(
    {
      kind       = var.kind
      location   = var.location
      sku        = local.sku
      properties = local.properties
    },
    local.identity != null ? { identity = local.identity } : {},
    var.tags != null ? { tags = var.tags } : {},
  )
}

# ── Resource provider registration check ─────────────────────────────────────

data "rest_resource" "provider_check" {
  id = "/subscriptions/${var.subscription_id}/providers/Microsoft.CognitiveServices"

  query = {
    api-version = ["2025-04-01"]
  }

  output_attrs = toset(["registrationState"])
}

# ── Name availability pre-check ──────────────────────────────────────────────
# POST /subscriptions/{id}/providers/Microsoft.CognitiveServices/checkNameAvailability
# Skipped when importing existing resources (check_existance = true).

resource "rest_operation" "check_name_availability" {
  count  = var.check_existance ? 0 : 1
  path   = "/subscriptions/${var.subscription_id}/providers/Microsoft.CognitiveServices/checkNameAvailability"
  method = "POST"

  query = {
    api-version = [local.api_version]
  }

  body = {
    name = var.account_name
    type = "Microsoft.CognitiveServices/accounts"
  }

  output_attrs = toset(["nameAvailable", "reason", "message"])
}

# ── Foundry Account ───────────────────────────────────────────────────────────

resource "rest_resource" "foundry_account" {
  path            = local.account_path
  create_method   = "PUT"
  check_existance = var.check_existance

  query = {
    api-version = [local.api_version]
  }

  body = local.body

  output_attrs = toset([
    "properties.provisioningState",
    "properties.endpoint",
    "properties.internalId",
    "properties.dateCreated",
    "properties.callRateLimit.rules",
    "identity.principalId",
    "identity.tenantId",
  ])

  lifecycle {
    precondition {
      condition     = contains(["Registered", "Registering"], data.rest_resource.provider_check.output.registrationState)
      error_message = "Resource provider Microsoft.CognitiveServices is not registered on subscription ${var.subscription_id}. Add to your config YAML:\n\n  azure_resource_provider_registrations:\n    cognitiveservices:\n      resource_provider_namespace: Microsoft.CognitiveServices"
    }

    precondition {
      condition     = var.check_existance || try(rest_operation.check_name_availability[0].output.nameAvailable, false)
      error_message = "Foundry account name '${var.account_name}' is not available: ${try(rest_operation.check_name_availability[0].output.message, "unknown reason")}. Choose a different account_name."
    }

    precondition {
      condition     = var.encryption_key_source != "Microsoft.KeyVault" || var.encryption_key_vault_uri != null
      error_message = "encryption_key_vault_uri is required when encryption_key_source is 'Microsoft.KeyVault'."
    }

    precondition {
      condition     = var.encryption_key_source != "Microsoft.KeyVault" || var.encryption_key_name != null
      error_message = "encryption_key_name is required when encryption_key_source is 'Microsoft.KeyVault'."
    }

    precondition {
      condition     = (var.identity_type == null || !contains(["UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)) || var.identity_user_assigned_identity_ids != null
      error_message = "identity_user_assigned_identity_ids is required when identity_type is 'UserAssigned' or 'SystemAssigned, UserAssigned'."
    }
  }

  # Provisioning is async — poll on provisioningState (ARM LRO pattern).
  poll_create = {
    status_locator    = "body.properties.provisioningState"
    default_delay_sec = 15
    status = {
      success = "Succeeded"
      pending = ["Creating", "Updating", "Accepted", "Running"]
    }
  }

  poll_update = {
    status_locator    = "body.properties.provisioningState"
    default_delay_sec = 15
    status = {
      success = "Succeeded"
      pending = ["Creating", "Updating", "Accepted", "Running"]
    }
  }

  # DELETE is async — poll until the resource returns 404.
  poll_delete = {
    status_locator    = "code"
    default_delay_sec = 10
    status = {
      success = "404"
      pending = ["202", "200"]
    }
  }
}
