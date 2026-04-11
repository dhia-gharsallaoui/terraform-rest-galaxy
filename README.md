# terraform-rest-galaxy

Agentic Infrastructure as Code — a Terraform root module designed for AI-assisted infrastructure management. Declare Azure, Entra ID, GitHub, and Kubernetes resources in YAML configuration files, and let AI agents (GitHub Copilot, coding assistants) generate, validate, and evolve infrastructure through conversation.

Built on the [`rest` provider](https://github.com/LaurentLesle/terraform-provider-rest), resources are resolved at plan time using cross-reference (`ref:`) expressions — no HCL authoring required.

## Why Agentic IaC?

Traditional IaC requires deep Terraform expertise to author and maintain HCL. This module inverts that model:

- **AI agents generate YAML configs** — describe what you need in natural language, and the agent produces a valid configuration file
- **Cross-references are self-documenting** — `ref:azure_resource_groups.app.resource_group_name` makes dependencies explicit and discoverable
- **Module library is pre-built** — 70+ sub-modules cover common Azure patterns, so agents compose rather than create from scratch
- **Validation is built-in** — `terraform plan` catches errors before any resource is created
- **Skills drive agent behavior** — `.github/skills/` contains agent instructions for creating modules, fixing drift, generating diagrams, and running tests

## Features

- **YAML-driven** — declare resources in configuration files, not HCL
- **Cross-reference resolution** — `ref:azure_resource_groups.app.resource_group_name` resolves across resource types
- **Remote state references** — `ref:remote_states.launchpad.azure_values...` bridges state boundaries
- **External validation** — live API checks for billing accounts, tenants, and other data sources
- **Multi-provider** — Azure ARM, Microsoft Graph, GitHub REST, Kubernetes API in one module
- **70+ sub-modules** — each maps to a single Azure/Entra ID/GitHub/K8s resource

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.8.0 |
| [LaurentLesle/rest](https://github.com/LaurentLesle/terraform-provider-rest) | ~> 1.0 |

## Quick Start

```bash
# Authenticate
export TF_VAR_azure_access_token=$(az account get-access-token \
  --resource https://management.azure.com --query accessToken -o tsv)
export TF_VAR_subscription_id=$(az account show --query id -o tsv)

# Init
terraform init -backend=false

# Plan with a configuration file
terraform plan -var="config_file=configurations/storage_account_minimum.yaml"

# Apply
terraform apply -var="config_file=configurations/storage_account_minimum.yaml"
```

Or use the wrapper script:

```bash
./tf.sh plan configurations/storage_account_minimum.yaml
./tf.sh apply configurations/storage_account_minimum.yaml
```

## Module Inventory

### Azure (56 modules)

| Category | Modules |
|----------|---------|
| Compute | `managed_cluster` (AKS) |
| Networking | `virtual_network`, `virtual_network_peering`, `virtual_network_gateway`, `virtual_network_gateway_connection`, `virtual_hub`, `virtual_hub_connection`, `virtual_wan`, `vpn_gateway`, `load_balancer`, `public_ip_address`, `network_interface`, `route_table`, `routing_intent`, `express_route_circuit`, `express_route_circuit_peering`, `express_route_port`, `azure_firewall`, `firewall_policy`, `private_endpoint`, `private_dns_zone`, `dns_zone`, `dns_record_set`, `dns_resolver`, `github_network_settings`, `network_manager` |
| Storage | `storage_account`, `storage_account_container` |
| Database | `postgresql_flexible_server`, `postgresql_flexible_server_administrator`, `redis_enterprise_cluster`, `redis_enterprise_database` |
| Security | `key_vault`, `key_vault_key`, `role_assignment`, `management_lock` |
| Identity | `user_assigned_identity`, `federated_identity_credential` |
| Communication | `communication_service`, `email_communication_service`, `email_communication_service_domain` |
| Billing | `billing_associated_tenant`, `billing_permission_request`, `billing_role_assignment` |
| Platform | `resource_group`, `subscription`, `resource_provider_registration`, `resource_provider_feature`, `ipam_pool`, `ipam_static_cidr`, `ciam_directory`, `app_service_domain`, `container_registry`, `container_registry_import`, `arc_connected_cluster`, `arc_kubernetes_extension` |

### Entra ID (7 modules)

`application`, `service_principal`, `group`, `group_member`, `user`, `app_role_assignment`, `oauth2_permission_grant`

### GitHub (4 modules)

`hosted_runner`, `runner_group`, `repository_secret`, `repository_action_variable`

### Kubernetes (8 modules)

`kind_cluster`, `namespace`, `service_account`, `cluster_role_binding`, `config_map`, `deployment`, `job`, `helm_release`

## Hero Modules

Hero modules provide exhaustive coverage of their resource type: all writable spec properties exposed as variables, schema-derived `validation` blocks, an extended `complete/` example covering every variable group, and multiple `configurations/*.yaml` files demonstrating distinct real-world scenarios.

| Module | Provider | Configurations | Notes |
|--------|----------|---------------|-------|
| *(none yet — use `/tf-fix <name> --hero` or `/tf-module <name> --hero` to promote)* | | | |

> To add a module to this list, it must satisfy all hero completion criteria defined in `.github/skills/tf-fix/SKILL.md` (Hero Mode section).

## Configuration Files

Configurations live in `configurations/` as YAML files. Each file declares the resources to manage and an optional backend:

```yaml
terraform_backend:
  type: azurerm
  resource_group_name: rg-terraform-state
  storage_account_name: stterraformstate001
  container_name: tfstate
  key: myworkload.tfstate

azure_resource_groups:
  app:
    resource_group_name: rg-myapp
    location: westeurope

azure_storage_accounts:
  data:
    resource_group_name: ref:azure_resource_groups.app.resource_group_name
    account_name: stmyappdata001
    location: ref:azure_resource_groups.app.location
    sku_name: Standard_LRS
    kind: StorageV2
```

## Examples

- [`examples/azure/resource_group`](examples/azure/resource_group) — minimal resource group
- [`examples/azure/storage_account`](examples/azure/storage_account) — storage account with examples

## Testing

38 test files covering unit tests (isolated sub-modules) and integration tests (full config resolution):

```bash
# Run all plan-only tests (no credentials needed)
terraform test -filter=tests/unit_azure_billing_associated_tenant.tftest.hcl

# Run integration tests (requires Azure credentials)
terraform test -filter=tests/integration_azure_billing_associated_tenant.tftest.hcl
```

CI runs automatically on push to `main` via GitHub Actions.

## CI/CD

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| [`terraform-test.yml`](.github/workflows/terraform-test.yml) | Push to `main`, PRs | Plan-only + apply tests |
| [`release.yml`](.github/workflows/release.yml) | `v*` tag push | Security checks, tests, GitHub Release |
| [`deploy.yml`](.github/workflows/deploy.yml) | Reusable workflow | Config repo deployment pipeline |

## Documentation

- [YAML Configuration Reference](docs/yaml-reference.md) — all 78 resources with attributes and YAML examples ([Azure](docs/yaml-reference-azure.md) · [Entra ID](docs/yaml-reference-entraid.md) · [GitHub](docs/yaml-reference-github.md) · [Kubernetes](docs/yaml-reference-k8s.md))
- [Cross-References and Externals](docs/references.md) — `ref:`, `externals`, `remote_states`, `caller`
- [Consumer Documentation](.github/CONSUMER_DOCUMENTATION.md) — setup guide for config repo teams
- [Version Upgrade Guide](.github/VERSION_UPGRADE_GUIDE.md) — safe upgrade procedures
- [Backend Interface Contract](.github/BACKEND_INTERFACE_CONTRACT.md) — state backend validation rules

## License

[MIT](LICENSE)
