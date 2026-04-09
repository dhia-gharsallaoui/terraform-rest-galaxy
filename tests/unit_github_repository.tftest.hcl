# Unit test — modules/github/repository
# Tests the sub-module in isolation (plan only).
# Run: terraform test -filter=tests/unit_github_repository.tftest.hcl

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

run "plan_repository_minimum" {
  command = plan

  module {
    source = "./modules/github/repository"
  }

  variables {
    organization = "my-org"
    name         = "my-demo-repo"
  }

  assert {
    condition     = output.name == "my-demo-repo"
    error_message = "Name output must echo input."
  }

  assert {
    condition     = output.organization == "my-org"
    error_message = "Organization output must echo input."
  }

  assert {
    condition     = output.visibility == "private"
    error_message = "Visibility output must default to 'private' when unset."
  }
}

run "plan_repository_complete" {
  command = plan

  module {
    source = "./modules/github/repository"
  }

  variables {
    organization           = "my-org"
    name                   = "my-demo-repo-complete"
    description            = "A demo repo created by terraform-rest-galaxy tests"
    homepage               = "https://example.com"
    visibility             = "private"
    auto_init              = true
    gitignore_template     = "Terraform"
    license_template       = "mit"
    has_issues             = true
    has_projects           = false
    has_wiki               = false
    has_downloads          = true
    delete_branch_on_merge = true
    allow_squash_merge     = true
    allow_merge_commit     = false
    allow_rebase_merge     = true
    allow_auto_merge       = false
  }

  assert {
    condition     = output.name == "my-demo-repo-complete"
    error_message = "Name output must echo input."
  }

  assert {
    condition     = output.visibility == "private"
    error_message = "Visibility output must echo input."
  }
}
