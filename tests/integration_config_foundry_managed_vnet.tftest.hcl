# Integration test — configurations/foundry_managed_vnet.yaml (plan only)
# Run: terraform test -filter=tests/integration_config_foundry_managed_vnet.tftest.hcl
#
# Validates the full foundry managed vnet configuration including:
#   - ref: resolution across all layers (RG → feature flag → account → managed network → deployments)
#   - Variable types and validation rules
#   - Dependency graph (layer ordering)
#
# IMPORTANT: Do NOT add a provider "rest" block here.
# The root module's provider config flows through automatically.
# Adding one causes "Provider type mismatch" errors with unit tests.

variable "access_token" {
  type      = string
  sensitive = true
  default   = "placeholder"
}

variable "graph_access_token" {
  type      = string
  sensitive = true
  default   = "placeholder"
}

run "plan_foundry_managed_vnet" {
  command = plan

  variables {
    config_file     = "configurations/foundry_managed_vnet.yaml"
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = output.azure_values.azure_resource_groups["foundry"] != null
    error_message = "Plan failed — resource group 'foundry' not resolved."
  }

  assert {
    condition     = output.azure_values.azure_resource_provider_features["foundry_managed_vnet"] != null
    error_message = "Plan failed — feature flag 'foundry_managed_vnet' not resolved."
  }

  assert {
    condition     = output.azure_values.azure_foundry_accounts["main"] != null
    error_message = "Plan failed — foundry account 'main' not resolved."
  }

  assert {
    condition     = output.azure_values.azure_foundry_accounts["main"].account_name == "my-foundry-hub"
    error_message = "Plan failed — account_name must be 'my-foundry-hub'."
  }

  assert {
    condition     = output.azure_values.azure_foundry_managed_networks["main"] != null
    error_message = "Plan failed — foundry managed network 'main' not resolved."
  }

  assert {
    condition     = output.azure_values.azure_foundry_managed_networks["main"].isolation_mode == "AllowOnlyApprovedOutbound"
    error_message = "Plan failed — isolation_mode must be 'AllowOnlyApprovedOutbound'."
  }

  assert {
    condition     = output.azure_values.azure_foundry_deployments["gpt4o"] != null
    error_message = "Plan failed — deployment 'gpt4o' not resolved."
  }

  assert {
    condition     = output.azure_values.azure_foundry_deployments["gpt4o"].model_name == "gpt-4o"
    error_message = "Plan failed — gpt4o model_name must be 'gpt-4o'."
  }

  assert {
    condition     = output.azure_values.azure_foundry_deployments["embeddings"] != null
    error_message = "Plan failed — deployment 'embeddings' not resolved."
  }

  assert {
    condition     = output.azure_values.azure_foundry_deployments["embeddings"].sku_name == "Standard"
    error_message = "Plan failed — embeddings sku_name must be 'Standard'."
  }
}
