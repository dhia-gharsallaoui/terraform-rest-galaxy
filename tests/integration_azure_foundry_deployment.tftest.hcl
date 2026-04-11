# Integration test — foundry_deployment via root module (plan only)
# Run: terraform test -filter=tests/integration_azure_foundry_deployment.tftest.hcl
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

run "plan_foundry_deployment" {
  command = plan

  variables {
    azure_foundry_deployments = {
      gpt4o = {
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
    }
  }

  assert {
    condition     = output.azure_values.azure_foundry_deployments["gpt4o"].deployment_name == "gpt-4o"
    error_message = "Plan failed — deployment_name must echo input."
  }

  assert {
    condition     = output.azure_values.azure_foundry_deployments["gpt4o"].model_name == "gpt-4o"
    error_message = "Plan failed — model_name must echo input."
  }

  assert {
    condition     = output.azure_values.azure_foundry_deployments["gpt4o"].sku_name == "GlobalStandard"
    error_message = "Plan failed — sku_name must echo input."
  }
}
