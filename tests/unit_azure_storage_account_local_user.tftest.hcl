# Unit test — modules/azure/storage_account_local_user
# Tests the sub-module in isolation (plan only). No real credentials needed.
# Run: terraform test -filter=tests/unit_azure_storage_account_local_user.tftest.hcl

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

run "plan_storage_account_local_user" {
  command = plan

  module {
    source = "./modules/azure/storage_account_local_user"
  }

  variables {
    subscription_id     = var.subscription_id
    resource_group_name = "rg-test"
    account_name        = "mydatalake001"
    username            = "sftp-user01"
    permission_scopes = [
      {
        service       = "blob"
        resource_name = "uploads"
        permissions   = "rwdl"
      }
    ]
  }

  assert {
    condition     = output.id == "/subscriptions/${var.subscription_id}/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/mydatalake001/localUsers/sftp-user01"
    error_message = "ARM ID must be correctly formed."
  }

  assert {
    condition     = output.name == "sftp-user01"
    error_message = "name output must echo input username."
  }

  assert {
    condition     = output.api_version == "2025-08-01"
    error_message = "api_version output must be 2025-08-01."
  }
}

run "plan_storage_account_local_user_with_ssh_key" {
  command = plan

  module {
    source = "./modules/azure/storage_account_local_user"
  }

  variables {
    subscription_id     = var.subscription_id
    resource_group_name = "rg-test"
    account_name        = "mydatalake001"
    username            = "sftp-poweruser"
    permission_scopes = [
      {
        service       = "blob"
        resource_name = "uploads"
        permissions   = "rwdlc"
      },
      {
        service       = "file"
        resource_name = "fileshare1"
        permissions   = "rwdl"
      }
    ]
    home_directory          = "uploads/home"
    allow_acl_authorization = false
    ssh_authorized_keys = [
      {
        description = "my-key"
        key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0"
      }
    ]
  }

  assert {
    condition     = output.id == "/subscriptions/${var.subscription_id}/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/mydatalake001/localUsers/sftp-poweruser"
    error_message = "ARM ID must be correctly formed for complete configuration."
  }

  assert {
    condition     = output.name == "sftp-poweruser"
    error_message = "name output must echo input username."
  }
}
