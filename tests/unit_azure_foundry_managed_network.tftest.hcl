# Unit test — modules/azure/foundry_managed_network
# Tests the sub-module in isolation (plan only).
# Run: terraform test -filter=tests/unit_azure_foundry_managed_network.tftest.hcl

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

run "plan_foundry_managed_network" {
  command = plan

  module {
    source = "./modules/azure/foundry_managed_network"
  }

  variables {
    subscription_id     = var.subscription_id
    resource_group_name = "rg-test"
    account_name        = "my-foundry-test"
    location            = "francecentral"
    isolation_mode      = "AllowOnlyApprovedOutbound"
  }

  assert {
    condition     = output.id == "/subscriptions/${var.subscription_id}/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/my-foundry-test/managedNetworks/default"
    error_message = "ARM ID must be correctly formed."
  }

  assert {
    condition     = output.account_name == "my-foundry-test"
    error_message = "account_name output must echo input."
  }

  assert {
    condition     = output.isolation_mode == "AllowOnlyApprovedOutbound"
    error_message = "isolation_mode output must echo input."
  }

  assert {
    condition     = output.resource_group_name == "rg-test"
    error_message = "resource_group_name output must echo input."
  }
}
