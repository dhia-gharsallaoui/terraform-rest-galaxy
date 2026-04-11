# ── Scope ────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group containing the parent Foundry account."
}

variable "account_name" {
  type        = string
  description = "The name of the parent Foundry account (Microsoft.CognitiveServices/accounts)."
}

variable "location" {
  type        = string
  default     = "francecentral"
  description = <<-EOT
    Azure region of the parent Foundry account. Must be one of the regions that
    support managed virtual network (preview). The managed network is always
    co-located with its parent account.

    Supported regions: eastus, eastus2, japaneast, francecentral, uaenorth,
    brazilsouth, spaincentral, germanywestcentral, italynorth, southcentralus,
    westcentralus, australiaeast, swedencentral, canadaeast, southafricanorth,
    westeurope, westus, westus3, southindia, uksouth.
  EOT

  validation {
    condition = contains([
      "eastus", "eastus2", "japaneast", "francecentral", "uaenorth",
      "brazilsouth", "spaincentral", "germanywestcentral", "italynorth",
      "southcentralus", "westcentralus", "australiaeast", "swedencentral",
      "canadaeast", "southafricanorth", "westeurope", "westus", "westus3",
      "southindia", "uksouth",
    ], var.location)
    error_message = "Managed virtual network (preview) is only supported in: eastus, eastus2, japaneast, francecentral, uaenorth, brazilsouth, spaincentral, germanywestcentral, italynorth, southcentralus, westcentralus, australiaeast, swedencentral, canadaeast, southafricanorth, westeurope, westus, westus3, southindia, uksouth."
  }
}

# ── Required ──────────────────────────────────────────────────────────────────

variable "isolation_mode" {
  type        = string
  default     = "AllowOnlyApprovedOutbound"
  description = <<-EOT
    The managed network isolation mode. Controls how Agent egress traffic is secured.

    - AllowOnlyApprovedOutbound (default): Restricts outbound to approved destinations
      only (service tags, private endpoints, FQDN rules). A managed Azure Firewall is
      created automatically when FQDN rules are added. Recommended for production.
    - AllowInternetOutbound: Allows all outbound internet traffic. Simpler setup but
      provides weaker data exfiltration protection.
    - Disabled: No managed network isolation. Use with a custom VNet instead.

    WARNING: This setting is IRREVERSIBLE. Once set to AllowInternetOutbound or
    AllowOnlyApprovedOutbound, it cannot be changed back to Disabled. Changing from
    AllowInternetOutbound to AllowOnlyApprovedOutbound is also not supported.
  EOT

  validation {
    condition     = contains(["AllowInternetOutbound", "AllowOnlyApprovedOutbound", "Disabled"], var.isolation_mode)
    error_message = "isolation_mode must be one of: AllowInternetOutbound, AllowOnlyApprovedOutbound, Disabled."
  }
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "managed_network_kind" {
  type        = string
  default     = "V2"
  description = <<-EOT
    The managed network kind. Controls the access control model:
    - V2 (default): Granular access controls. Recommended for new deployments.
    - V1: Legacy access controls.

    WARNING: Once set to V2, it cannot be reverted to V1.
  EOT

  validation {
    condition     = contains(["V1", "V2"], var.managed_network_kind)
    error_message = "managed_network_kind must be 'V1' or 'V2'."
  }
}

variable "firewall_sku" {
  type        = string
  default     = "Standard"
  description = <<-EOT
    The Azure Firewall SKU used for FQDN outbound rules. Only relevant when
    isolation_mode is 'AllowOnlyApprovedOutbound' and FQDN rules are added.

    - Standard (default): Full feature set including threat intelligence-based filtering.
    - Basic: Reduced cost option. Sufficient for most scenarios without advanced filtering.

    WARNING: Cannot be changed after initial deployment.
  EOT

  validation {
    condition     = contains(["Basic", "Standard"], var.firewall_sku)
    error_message = "firewall_sku must be 'Basic' or 'Standard'."
  }
}

variable "outbound_rules" {
  type = map(object({
    type     = string
    category = optional(string, "UserDefined")
    # FQDN rule fields
    fqdn_destination = optional(string, null)
    # PrivateEndpoint rule fields
    private_endpoint_service_resource_id = optional(string, null)
    private_endpoint_subresource_target  = optional(string, null)
    private_endpoint_fqdns               = optional(list(string), null)
    # ServiceTag rule fields
    service_tag                  = optional(string, null)
    service_tag_action           = optional(string, "Allow")
    service_tag_protocol         = optional(string, null)
    service_tag_port_ranges      = optional(string, null)
    service_tag_address_prefixes = optional(list(string), null)
  }))
  default     = null
  description = <<-EOT
    Map of outbound rules for the managed network. Each key is the rule name.

    Three rule types are supported:

    FQDN rule (allows outbound to a specific domain; requires AllowOnlyApprovedOutbound + firewall):
      my_fqdn_rule = {
        type             = "FQDN"
        fqdn_destination = "*.example.com"
      }

    PrivateEndpoint rule (creates a managed private endpoint to an Azure resource):
      my_storage_pe = {
        type                                 = "PrivateEndpoint"
        private_endpoint_service_resource_id = "/subscriptions/.../storageAccounts/mystorage"
        private_endpoint_subresource_target  = "blob"
      }

    ServiceTag rule (allows outbound to an Azure service tag):
      my_service_tag_rule = {
        type                = "ServiceTag"
        service_tag         = "AzureActiveDirectory"
        service_tag_action  = "Allow"
        service_tag_protocol = "TCP"
        service_tag_port_ranges = "443"
      }

    NOTE: FQDN rules are only supported on ports 80 and 443.
    NOTE: PrivateEndpoint rules require the Foundry managed identity to have
          the 'Azure AI Enterprise Network Connection Approver' role on the target resource.
  EOT

  validation {
    condition = var.outbound_rules == null || alltrue([
      for name, rule in var.outbound_rules : contains(["FQDN", "PrivateEndpoint", "ServiceTag"], rule.type)
    ])
    error_message = "Each outbound rule type must be one of: FQDN, PrivateEndpoint, ServiceTag."
  }

  validation {
    condition = var.outbound_rules == null || alltrue([
      for name, rule in var.outbound_rules :
      rule.type != "FQDN" || rule.fqdn_destination != null
    ])
    error_message = "FQDN outbound rules require fqdn_destination to be set."
  }

  validation {
    condition = var.outbound_rules == null || alltrue([
      for name, rule in var.outbound_rules :
      rule.type != "PrivateEndpoint" || rule.private_endpoint_service_resource_id != null
    ])
    error_message = "PrivateEndpoint outbound rules require private_endpoint_service_resource_id to be set."
  }

  validation {
    condition = var.outbound_rules == null || alltrue([
      for name, rule in var.outbound_rules :
      rule.type != "ServiceTag" || rule.service_tag != null
    ])
    error_message = "ServiceTag outbound rules require service_tag to be set."
  }

  validation {
    condition = var.outbound_rules == null || alltrue([
      for name, rule in var.outbound_rules :
      rule.category == null || contains(["Dependency", "Recommended", "Required", "UserDefined"], rule.category)
    ])
    error_message = "outbound rule category must be one of: Dependency, Recommended, Required, UserDefined."
  }
}
