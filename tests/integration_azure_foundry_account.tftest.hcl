# Integration test — foundry_account (plan only)
# Run: terraform test -filter=tests/integration_azure_foundry_account.tftest.hcl
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

run "plan_foundry_account" {
  command = plan

  variables {
    azure_foundry_accounts = {
      test = {
        subscription_id     = var.subscription_id
        resource_group_name = "rg-test"
        account_name        = "my-foundry-test"
        location            = "francecentral"
        sku_name            = "S0"
      }
    }
  }

  assert {
    condition     = output.azure_values.azure_foundry_accounts["test"].id != null
    error_message = "Plan failed — foundry account 'test' not found."
  }

  assert {
    condition     = output.azure_values.azure_foundry_accounts["test"].account_name == "my-foundry-test"
    error_message = "Plan failed — account_name must echo input."
  }
}
