# Unit test — modules/github/organization_variable
# Tests the sub-module in isolation (plan only).
# Run: terraform test -filter=tests/unit_github_organization_variable.tftest.hcl

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

run "plan_organization_variable_all" {
  command = plan

  module {
    source = "./modules/github/organization_variable"
  }

  variables {
    organization = "my-org"
    name         = "DEFAULT_REGION"
    value        = "us-east-1"
    visibility   = "all"
  }

  assert {
    condition     = output.name == "DEFAULT_REGION"
    error_message = "Name output must echo input."
  }

  assert {
    condition     = output.organization == "my-org"
    error_message = "Organization output must echo input."
  }

  assert {
    condition     = output.visibility == "all"
    error_message = "Visibility output must echo input."
  }

  assert {
    condition     = output.value == "us-east-1"
    error_message = "Value output must echo input."
  }
}

run "plan_organization_variable_selected" {
  command = plan

  module {
    source = "./modules/github/organization_variable"
  }

  variables {
    organization            = "my-org"
    name                    = "SHARED_REGION"
    value                   = "us-west-2"
    visibility              = "selected"
    selected_repository_ids = [1, 2, 3]
  }

  assert {
    condition     = output.visibility == "selected"
    error_message = "Visibility output must be 'selected'."
  }
}
