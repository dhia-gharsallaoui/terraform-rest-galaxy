# Unit test — modules/azure/foundry_account
# Tests the sub-module in isolation (plan only).
# NOTE: This module has a provider_check data source for Microsoft.CognitiveServices
# and a check_name_availability operation, so plan will fail with a placeholder token.
# The test is kept for structure completeness — assertions cover plan-time-known outputs.
# Run: terraform test -filter=tests/unit_azure_foundry_account.tftest.hcl

variable "access_token" {
  type      = string
  sensitive = true
  default   = "placeholder"
}

provider "rest" {
  base_url = "https://management.azure.com"
  security = {
    http = {
      token = {
        token = var.access_token
      }
    }
  }
}

variable "subscription_id" {
  type    = string
  default = "00000000-0000-0000-0000-000000000000"
}

run "plan_foundry_account" {
  command = plan

  module {
    source = "./modules/azure/foundry_account"
  }

  variables {
    subscription_id     = var.subscription_id
    resource_group_name = "rg-test"
    account_name        = "my-foundry-test"
    location            = "francecentral"
    sku_name            = "S0"
  }

  assert {
    condition     = output.id == "/subscriptions/${var.subscription_id}/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/my-foundry-test"
    error_message = "ARM ID must be correctly formed."
  }

  assert {
    condition     = output.account_name == "my-foundry-test"
    error_message = "account_name output must echo input."
  }

  assert {
    condition     = output.location == "francecentral"
    error_message = "location output must echo input."
  }

  assert {
    condition     = output.resource_group_name == "rg-test"
    error_message = "resource_group_name output must echo input."
  }
}
