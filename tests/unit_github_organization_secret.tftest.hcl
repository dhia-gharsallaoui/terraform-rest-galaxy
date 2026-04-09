# Unit test — modules/github/organization_secret
# Tests the sub-module in isolation (plan only).
# The data.rest_resource.public_key call is overridden via override_data so
# the plan does not need a real GitHub token.
# Run: terraform test -filter=tests/unit_github_organization_secret.tftest.hcl

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

run "plan_organization_secret_all" {
  command = plan

  module {
    source = "./modules/github/organization_secret"
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
    organization    = "my-org"
    secret_name     = "NPM_TOKEN"
    plaintext_value = "placeholder"
    visibility      = "all"
  }

  assert {
    condition     = output.name == "NPM_TOKEN"
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
}

run "plan_organization_secret_selected" {
  command = plan

  module {
    source = "./modules/github/organization_secret"
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
    organization            = "my-org"
    secret_name             = "SHARED_DEPLOY_KEY"
    plaintext_value         = "placeholder"
    visibility              = "selected"
    selected_repository_ids = [100, 200, 300]
  }

  assert {
    condition     = output.visibility == "selected"
    error_message = "Visibility output must be 'selected'."
  }
}
