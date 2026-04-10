# Unit test — modules/github/environment_secret
# Tests the sub-module in isolation (plan only).
# The data.rest_resource.public_key call is overridden via override_data so
# the plan does not need a real GitHub token.
# Run: terraform test -filter=tests/unit_github_environment_secret.tftest.hcl

provider "rest" {
  base_url = "https://api.github.com"
  security = {
    http = {
      token = {
        token = "placeholder"
      }
    }
  }
}

run "plan_environment_secret" {
  command = plan

  module {
    source = "./modules/github/environment_secret"
  }

  override_data {
    target = data.rest_resource.public_key
    values = {
      output = {
        key    = "u+6Y0H7v9qW7iJvF0aB3cDeFgHiJkLmN0pQrStUvWxY="
        key_id = "568250167242549743"
      }
    }
  }

  variables {
    owner            = "my-org"
    repo             = "my-demo-repo"
    environment_name = "staging"
    secret_name      = "API_KEY"
    plaintext_value  = "placeholder"
  }

  assert {
    condition     = output.name == "API_KEY"
    error_message = "Name output must echo input."
  }

  assert {
    condition     = output.owner == "my-org"
    error_message = "Owner output must echo input."
  }

  assert {
    condition     = output.repo == "my-demo-repo"
    error_message = "Repo output must echo input."
  }

  assert {
    condition     = output.environment_name == "staging"
    error_message = "Environment name output must echo input."
  }
}
