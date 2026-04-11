# Unit test — modules/azure/github_network_settings
# Tests the sub-module in isolation (plan only).
# Run: terraform test -filter=tests/unit_azure_github_network_settings.tftest.hcl
#
# ci:skip
# GitHub.Network is a partnership-only Azure resource provider that cannot be
# registered in a standard subscription. The provider_check precondition will
# always fire in CI. Run this test manually against a subscription with the
# GitHub-Azure network integration enabled.

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

run "plan_github_network_settings" {
  command = plan

  module {
    source = "./modules/azure/github_network_settings"
  }

  variables {
    subscription_id       = var.subscription_id
    resource_group_name   = "rg-github-runners"
    network_settings_name = "ns-runners"
    location              = "westeurope"
    subnet_id             = "/subscriptions/${var.subscription_id}/resourceGroups/rg-github-runners/providers/Microsoft.Network/virtualNetworks/vnet-runners/subnets/snet-runners"
    business_id           = "123456789"
  }

  assert {
    condition     = output.id == "/subscriptions/${var.subscription_id}/resourceGroups/rg-github-runners/providers/GitHub.Network/networkSettings/ns-runners"
    error_message = "ARM ID must be correctly formed."
  }

  assert {
    condition     = output.name == "ns-runners"
    error_message = "Name output must echo input."
  }

  assert {
    condition     = output.location == "westeurope"
    error_message = "Location output must echo input."
  }

  assert {
    condition     = output.subnet_id == "/subscriptions/${var.subscription_id}/resourceGroups/rg-github-runners/providers/Microsoft.Network/virtualNetworks/vnet-runners/subnets/snet-runners"
    error_message = "Subnet ID output must echo input."
  }

  assert {
    condition     = output.business_id == "123456789"
    error_message = "Business ID output must echo input."
  }
}
