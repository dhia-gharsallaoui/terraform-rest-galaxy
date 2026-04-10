# Unit test — modules/github/environment_variable
# Tests the sub-module in isolation (plan only).
# Run: terraform test -filter=tests/unit_github_environment_variable.tftest.hcl

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

run "plan_environment_variable" {
  command = plan

  module {
    source = "./modules/github/environment_variable"
  }

  variables {
    owner            = "my-org"
    repo             = "my-demo-repo"
    environment_name = "staging"
    name             = "API_URL"
    value            = "https://staging.example.com"
  }

  assert {
    condition     = output.name == "API_URL"
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

  assert {
    condition     = output.value == "https://staging.example.com"
    error_message = "Value output must echo input."
  }
}
