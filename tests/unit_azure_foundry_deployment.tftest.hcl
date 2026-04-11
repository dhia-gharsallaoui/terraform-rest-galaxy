# Unit test — modules/azure/foundry_deployment
# Tests the sub-module in isolation (plan only).
# NOTE: The model availability data source queries the real API at plan time.
# With a placeholder token, plan will fail on the data source lookup.
# Assertions cover plan-time-known outputs only.
# Run: terraform test -filter=tests/unit_azure_foundry_deployment.tftest.hcl

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

run "plan_foundry_deployment_minimum" {
  command = plan

  module {
    source = "./modules/azure/foundry_deployment"
  }

  variables {
    subscription_id     = var.subscription_id
    resource_group_name = "rg-test"
    account_name        = "my-foundry-test"
    location            = "francecentral"
    deployment_name     = "gpt-4o"
    model_format        = "OpenAI"
    model_name          = "gpt-4o"
    sku_name            = "GlobalStandard"
    sku_capacity        = 10
  }

  assert {
    condition     = output.id == "/subscriptions/${var.subscription_id}/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/my-foundry-test/deployments/gpt-4o"
    error_message = "ARM ID must be correctly formed."
  }

  assert {
    condition     = output.deployment_name == "gpt-4o"
    error_message = "deployment_name output must echo input."
  }

  assert {
    condition     = output.model_name == "gpt-4o"
    error_message = "model_name output must echo input."
  }

  assert {
    condition     = output.model_format == "OpenAI"
    error_message = "model_format output must echo input."
  }

  assert {
    condition     = output.sku_name == "GlobalStandard"
    error_message = "sku_name output must echo input."
  }

  assert {
    condition     = output.account_name == "my-foundry-test"
    error_message = "account_name output must echo input."
  }
}

run "plan_foundry_deployment_validation_sku" {
  command = plan

  module {
    source = "./modules/azure/foundry_deployment"
  }

  # Test: invalid sku_name should fail validation
  variables {
    subscription_id     = var.subscription_id
    resource_group_name = "rg-test"
    account_name        = "my-foundry-test"
    location            = "francecentral"
    deployment_name     = "gpt-4o"
    model_format        = "OpenAI"
    model_name          = "gpt-4o"
    sku_name            = "InvalidSKU"
  }

  expect_failures = [var.sku_name]
}

run "plan_foundry_deployment_validation_upgrade_option" {
  command = plan

  module {
    source = "./modules/azure/foundry_deployment"
  }

  # Test: invalid version_upgrade_option should fail validation
  variables {
    subscription_id        = var.subscription_id
    resource_group_name    = "rg-test"
    account_name           = "my-foundry-test"
    location               = "francecentral"
    deployment_name        = "gpt-4o"
    model_format           = "OpenAI"
    model_name             = "gpt-4o"
    sku_name               = "GlobalStandard"
    version_upgrade_option = "InvalidOption"
  }

  expect_failures = [var.version_upgrade_option]
}
