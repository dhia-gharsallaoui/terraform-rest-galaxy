# Integration test — configurations/multi_tenant_oidc_example.yaml
#
# Plans the full Contoso Platform multi-tenant config (5 repos, 12 environments,
# 16 subscriptions, OIDC, org secrets & variables) without requiring real tokens.
# The org-level public key data source is overridden via override_data.
#
# Run: terraform test -filter=tests/integration_config_multi_tenant_oidc_example.tftest.hcl
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

variable "github_token" {
  type      = string
  sensitive = true
  default   = "placeholder"
}

variable "subscription_id" {
  type    = string
  default = "00000000-0000-0000-0000-000000000000"
}

variable "arm_tenant_tokens" {
  type      = map(string)
  sensitive = true
  default = {
    "aaaaaaaa-1111-2222-3333-000000000001" = "placeholder-global"
    "aaaaaaaa-1111-2222-3333-000000000002" = "placeholder-dev"
    "aaaaaaaa-1111-2222-3333-000000000003" = "placeholder-prod"
    "aaaaaaaa-1111-2222-3333-000000000004" = "placeholder-gdpr"
  }
}

run "plan_multi_tenant_oidc_example" {
  command = plan

  variables {
    config_file       = "configurations/multi_tenant_oidc_example.yaml"
    subscription_id   = var.subscription_id
    arm_tenant_tokens = var.arm_tenant_tokens
  }

  # Mock org-level public-key fetch so plan succeeds without a real GitHub token.
  override_data {
    target = module.github_organization_secrets["contoso_shared_npm_token"].data.rest_resource.public_key
    values = {
      output = {
        key    = "u+6Y0H7v9qW7iJvF0aB3cDeFgHiJkLmN0pQrStUvWxY="
        key_id = "568250167242549743"
      }
    }
  }

  # ── Platform repositories (5) ────────────────────────────────────────────────
  assert {
    condition     = output.github_values.github_repositories["platform_global"].name == "Platform-Global"
    error_message = "Platform-Global repository name must match config."
  }

  assert {
    condition     = output.github_values.github_repositories["platform_networking"].name == "Platform-Networking"
    error_message = "Platform-Networking repository name must match config."
  }

  assert {
    condition     = output.github_values.github_repositories["platform_security"].name == "Platform-Security"
    error_message = "Platform-Security repository name must match config."
  }

  assert {
    condition     = output.github_values.github_repositories["platform_identity"].name == "Platform-Identity"
    error_message = "Platform-Identity repository name must match config."
  }

  assert {
    condition     = output.github_values.github_repositories["platform_management"].name == "Platform-Management"
    error_message = "Platform-Management repository name must match config."
  }

  # ── GitHub environments (12 = 4 domain repos × 3 tenants) ────────────────────
  assert {
    condition     = output.github_values.github_environments["networking_dev"].name == "dev"
    error_message = "Networking dev environment name must be 'dev'."
  }

  assert {
    condition     = output.github_values.github_environments["networking_prod"].name == "prod"
    error_message = "Networking prod environment name must be 'prod'."
  }

  assert {
    condition     = output.github_values.github_environments["networking_gdpr"].name == "gdpr"
    error_message = "Networking gdpr environment name must be 'gdpr'."
  }

  assert {
    condition     = output.github_values.github_environments["security_dev"].name == "dev"
    error_message = "Security dev environment name must be 'dev'."
  }

  assert {
    condition     = output.github_values.github_environments["identity_prod"].name == "prod"
    error_message = "Identity prod environment name must be 'prod'."
  }

  assert {
    condition     = output.github_values.github_environments["management_gdpr"].name == "gdpr"
    error_message = "Management gdpr environment name must be 'gdpr'."
  }

  # Verify environment count (12 environments total)
  assert {
    condition     = length(output.github_values.github_environments) == 12
    error_message = "Expected 12 GitHub environments (4 domain repos × 3 tenants)."
  }

  # ── Environment variables (36 = 12 envs × 3 vars) ───────────────────────────
  assert {
    condition     = output.github_values.github_environment_variables["networking_dev_subscription_id"].name == "TF_VAR_SUBSCRIPTION_ID"
    error_message = "Networking dev subscription_id env var name must match."
  }

  assert {
    condition     = output.github_values.github_environment_variables["networking_dev_tenant_id"].name == "TF_VAR_TENANT_ID"
    error_message = "Networking dev tenant_id env var name must match."
  }

  assert {
    condition     = output.github_values.github_environment_variables["networking_dev_client_id"].name == "TF_VAR_CLIENT_ID"
    error_message = "Networking dev client_id env var name must match."
  }

  assert {
    condition     = output.github_values.github_environment_variables["security_prod_subscription_id"].name == "TF_VAR_SUBSCRIPTION_ID"
    error_message = "Security prod subscription_id env var name must match."
  }

  assert {
    condition     = output.github_values.github_environment_variables["management_gdpr_tenant_id"].name == "TF_VAR_TENANT_ID"
    error_message = "Management gdpr tenant_id env var name must match."
  }

  # Verify environment variable count (36 total)
  assert {
    condition     = length(output.github_values.github_environment_variables) == 36
    error_message = "Expected 36 environment variables (12 envs × 3 vars)."
  }

  # ── Repo-level variables for Platform-Global (3) ─────────────────────────────
  assert {
    condition     = output.github_values.github_repository_action_variables["global_subscription_id"].name == "TF_VAR_SUBSCRIPTION_ID"
    error_message = "Global repo subscription_id variable name must match."
  }

  assert {
    condition     = output.github_values.github_repository_action_variables["global_tenant_id"].name == "TF_VAR_TENANT_ID"
    error_message = "Global repo tenant_id variable name must match."
  }

  assert {
    condition     = output.github_values.github_repository_action_variables["global_client_id"].name == "TF_VAR_CLIENT_ID"
    error_message = "Global repo client_id variable name must match."
  }

  assert {
    condition     = length(output.github_values.github_repository_action_variables) == 3
    error_message = "Expected 3 repo-level action variables (Global repo only)."
  }

  # ── Organization secret ──────────────────────────────────────────────────────
  assert {
    condition     = output.github_values.github_organization_secrets["contoso_shared_npm_token"].visibility == "all"
    error_message = "Organization secret visibility must match config."
  }

  assert {
    condition     = output.github_values.github_organization_secrets["contoso_shared_npm_token"].organization == "Contoso-Org"
    error_message = "Organization secret must resolve the organization ref: to Contoso-Org."
  }

  # ── Organization variable ────────────────────────────────────────────────────
  assert {
    condition     = output.github_values.github_organization_variables["contoso_default_region"].name == "DEFAULT_REGION"
    error_message = "Organization variable name must match config."
  }

  # ── Azure subscriptions (16 = 4 tenants × 4 domains) ────────────────────────
  assert {
    condition     = output.azure_values.azure_subscriptions["global_networking"].display_name == "Contoso-Global-Networking"
    error_message = "Global networking subscription display_name must match."
  }

  assert {
    condition     = output.azure_values.azure_subscriptions["dev_networking"].display_name == "Contoso-Dev-Networking"
    error_message = "Dev networking subscription display_name must match."
  }

  assert {
    condition     = output.azure_values.azure_subscriptions["prod_security"].display_name == "Contoso-Prod-Security"
    error_message = "Prod security subscription display_name must match."
  }

  assert {
    condition     = output.azure_values.azure_subscriptions["gdpr_management"].display_name == "Contoso-GDPR-Management"
    error_message = "GDPR management subscription display_name must match."
  }

  assert {
    condition     = length(output.azure_values.azure_subscriptions) == 16
    error_message = "Expected 16 Azure subscriptions (4 tenants × 4 domains)."
  }

  # ── Azure resource groups (16) ───────────────────────────────────────────────
  assert {
    condition     = output.azure_values.azure_resource_groups["global_identity"].resource_group_name == "rg-global-identity"
    error_message = "Global identity RG name must match."
  }

  assert {
    condition     = output.azure_values.azure_resource_groups["dev_networking"].resource_group_name == "rg-dev-networking"
    error_message = "Dev networking RG name must match."
  }

  assert {
    condition     = length(output.azure_values.azure_resource_groups) == 16
    error_message = "Expected 16 Azure resource groups (4 tenants × 4 domains)."
  }

  # ── Azure user assigned identities (16) ─────────────────────────────────────
  assert {
    condition     = output.azure_values.azure_user_assigned_identities["global_networking"].name == "id-global-networking-github-oidc"
    error_message = "Global networking UAI name must match."
  }

  assert {
    condition     = output.azure_values.azure_user_assigned_identities["dev_security"].name == "id-dev-security-github-oidc"
    error_message = "Dev security UAI name must match."
  }

  assert {
    condition     = length(output.azure_values.azure_user_assigned_identities) == 16
    error_message = "Expected 16 Azure user assigned identities (4 tenants × 4 domains)."
  }

  # ── Billing associated tenants (3) ───────────────────────────────────────────
  assert {
    condition     = output.azure_values.azure_billing_associated_tenants["contoso_dev"].display_name == "Contoso Platform Dev"
    error_message = "Dev billing associated tenant display_name must match."
  }

  assert {
    condition     = output.azure_values.azure_billing_associated_tenants["contoso_gdpr"].display_name == "Contoso Platform GDPR"
    error_message = "GDPR billing associated tenant display_name must match."
  }

  assert {
    condition     = length(output.azure_values.azure_billing_associated_tenants) == 3
    error_message = "Expected 3 billing associated tenants (dev, prod, gdpr)."
  }
}
