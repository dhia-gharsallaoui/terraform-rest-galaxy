# Integration test — foundry_managed_network (plan only)
# Run: terraform test -filter=tests/integration_azure_foundry_managed_network.tftest.hcl
#
# IMPORTANT: Do NOT add a provider "rest" block here.
# The root module's provider config flows through automatically.

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

variable "subscription_id" {
  type    = string
  default = "00000000-0000-0000-0000-000000000000"
}

run "plan_foundry_managed_network" {
  command = plan

  variables {
    azure_foundry_managed_networks = {
      test = {
        subscription_id     = var.subscription_id
        resource_group_name = "rg-test"
        account_name        = "my-foundry-test"
        location            = "francecentral"
        isolation_mode      = "AllowOnlyApprovedOutbound"
      }
    }
  }

  assert {
    condition     = output.azure_values.azure_foundry_managed_networks["test"].id != null
    error_message = "Plan failed — foundry managed network 'test' not found."
  }

  assert {
    condition     = output.azure_values.azure_foundry_managed_networks["test"].isolation_mode == "AllowOnlyApprovedOutbound"
    error_message = "Plan failed — isolation_mode must echo input."
  }
}
