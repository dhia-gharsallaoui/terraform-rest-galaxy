# Unit test — modules/github/environment
# Tests the sub-module in isolation (plan only).
# Run: terraform test -filter=tests/unit_github_environment.tftest.hcl

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

run "plan_environment_minimum" {
  command = plan

  module {
    source = "./modules/github/environment"
  }

  variables {
    owner = "my-org"
    repo  = "my-demo-repo"
    name  = "staging"
  }

  assert {
    condition     = output.name == "staging"
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
}

run "plan_environment_complete" {
  command = plan

  module {
    source = "./modules/github/environment"
  }

  variables {
    owner               = "my-org"
    repo                = "my-demo-repo"
    name                = "production"
    wait_timer          = 5
    prevent_self_review = true
    reviewers = [
      {
        type = "Team"
        id   = 12345
      }
    ]
    deployment_branch_policy = {
      protected_branches     = true
      custom_branch_policies = false
    }
  }

  assert {
    condition     = output.name == "production"
    error_message = "Name output must echo input."
  }
}
