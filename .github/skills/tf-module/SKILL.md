---
name: tf-module
description: "Create a new versioned Terraform module for an Azure resource, or implement an end-to-end multi-resource scenario, using the rest provider. Use when: creating a terraform module, new azure module, generate module, add resource module, scaffold terraform azure, tf_module, create module resource group, create module virtual network, create module storage account, rest_resource module, azure rest api terraform module, storage account with customer managed key, CMK encryption, end to end scenario, keyvault with private endpoint, storage with encryption key, implement scenario, multi-resource configuration, deploy resource group with storage and keyvault, hero module, hero quality module, scaffold hero, full coverage module"
argument-hint: "Azure resource type (e.g. 'Storage Account') or end-to-end scenario (e.g. 'storage account with customer-managed encryption key')"
---

# tf-module

Scaffold a production-quality versioned Terraform module for an Azure resource, **or** implement a complete multi-resource scenario end-to-end.

## When to Use

### Single-resource module
- You want to add a new Azure resource type to this repo
- You need a new `modules/azure/<resource_name>/` sub-module backed by the Azure REST API spec
- You want the root module updated automatically to expose the new resource via `for_each`
- Add `--hero` (or the user says "hero module") to also apply hero-quality criteria (see Hero Mode below)

### End-to-end scenario (composite configuration)
- The user describes a **goal** involving multiple resource types (e.g. "storage account with customer-managed encryption key", "key vault with private endpoint", "AKS cluster with managed identity and ACR pull")
- The request implies resources, permissions, and cross-references that span several modules
- A YAML configuration file in `configurations/` should demonstrate the full chain and the name of the file reflect the intent

## Procedure

### Mode A — Single resource module

Invoke the **Azure Rest Module Generator** agent (`@Azure Rest Module Generator`) with the Azure resource type as the argument.

```
@Azure Rest Module Generator <resource type>
```

Examples:
```
@Azure Rest Module Generator Resource Group
@Azure Rest Module Generator Virtual Network
@Azure Rest Module Generator Storage Account
```

The agent will:
1. Locate the official Azure REST API spec for the resource
2. Parse the PUT/GET/DELETE paths and writable/read-only properties
3. Generate `modules/azure/<resource_name>/` (versions.tf, variables.tf, main.tf, outputs.tf, README.md)
4. Update the root module — add `azure_<plural_resource_name>.tf` and append to `azure_outputs.tf`
5. Generate `examples/azure/<resource_name>/minimum/` and `examples/azure/<resource_name>/complete/` (calling the root module)
6. Generate tests (see `.github/instructions/testing.instructions.md` for conventions):
   - `tests/unit_azure_<resource_name>.tftest.hcl` — sub-module isolation test (plan only, with own provider block)
   - `tests/integration_azure_<resource_name>.tftest.hcl` — root module test (no provider block)
7. Run `terraform fmt` and `terraform validate` on all generated files
8. Run `terraform test` to verify both unit and integration tests pass

### Mode B — End-to-end scenario

When the user describes a high-level goal rather than a single resource type, the agent must decompose the scenario, plan, and **wait for user validation** before implementing.

#### Step B.1 — Inventory existing modules

Scan `modules/azure/*/` and the root `azure_*.tf` files to build a catalogue of what already exists:
- List every existing sub-module directory under `modules/azure/`
- For each, note the resource type, key variables, and key outputs (especially `id`, `name`, `principal_id`, `vault_uri`, etc.)
- Note which `ref:` resolution layers already exist in `azure_config.tf`

#### Step B.2 — Decompose the scenario into resources

From the user's intent, identify **every** Azure resource type required — including **all implicit infrastructure dependencies** the user did not explicitly name. The user describes a goal; the agent must derive the full resource graph.

For example:
- "key vault with private endpoint" implies: **resource_group**, **virtual_network**, **subnet**, **private_endpoint**, **private_dns_zone**, **private_dns_zone_virtual_network_link**, **key_vault** — not just key vault and private endpoint.
- "storage account with CMK" implies: **resource_group**, **user_assigned_identity**, **key_vault**, **key_vault_key**, **role_assignment**, **storage_account**.

For each resource, classify it as:

| Classification | Meaning |
|---|---|
| **REUSE** | Module already exists in `modules/azure/` and no changes needed |
| **EXTEND** | Module exists but needs new variables/properties added (e.g. encryption fields on storage account) |
| **CREATE** | Module does not exist — must be generated from the Azure REST API spec |

#### Step B.3 — Map the dependency chain

Determine the ordering layers for `azure_config.tf` ref-resolution:

- **Layer 0**: Resources with no cross-references (e.g. `azure_resource_groups`)
- **Layer 1**: Resources that depend only on Layer 0 (e.g. `azure_user_assigned_identities`, `azure_key_vaults`)
- **Layer 2**: Resources that depend on Layer 1 (e.g. `azure_key_vault_keys`, `azure_role_assignments`)
- **Layer N**: Resources that depend on all previous layers (e.g. `azure_storage_accounts` with CMK)

For each resource, list the `ref:` expressions it will use and which output they resolve from.

#### Step B.4 — Present the plan and wait for validation

Present the plan in a structured format showing:

1. **Reused / Extended / Created table** — every module, its status, and what changes (if any)
2. **Dependency chain** — the full `ref:` wiring from root resources to leaf resources
3. **Files to create or modify** — exhaustive list of files touched
4. **Configuration YAML** — the target `configurations/<scenario_name>.yaml` structure

**CRITICAL: Do NOT proceed to implementation until the user explicitly validates the plan.**

#### Step B.5 — Implement (after user validation)

For each **CREATE** module, follow the full Mode A workflow (Steps 1–7 from the agent).

For each **EXTEND** module:
1. Re-read the Azure REST API spec for the properties to add
2. Add new variables to `modules/azure/<resource_name>/variables.tf`
3. Update the `body` locals in `modules/azure/<resource_name>/main.tf`
4. Add new outputs to `modules/azure/<resource_name>/outputs.tf`
5. Update the root `azure_<plural_resource_name>.tf` variable type and module block
6. Update `azure_config.tf` if new ref-resolution layers are needed

After all modules are ready:
1. Update `azure_config.tf` with the new ref-resolution layers
2. Update `azure_outputs.tf` to include all new resource types
3. Create the configuration YAML file in `configurations/` — **always include a `terraform_backend` block** (see Conventions below)
4. Create the configuration lifecycle test (see Step B.6)
5. Run `terraform fmt -recursive` and `terraform validate`
6. Run the full lifecycle test: init → plan → apply → destroy (see Step B.7)

#### Step B.6 — Create configuration lifecycle test

Every configuration YAML file **must** have a matching `terraform test` file that validates it. The test file lives flat in `tests/` with the `integration_config_` prefix.

Create `tests/integration_config_<scenario_name>.tftest.hcl`:

```hcl
# Integration test — configurations/<scenario_name>.yaml
# Run: terraform test -filter=tests/integration_config_<scenario_name>.tftest.hcl

# IMPORTANT: Do NOT add a provider "rest" block here.
# The root module's provider config flows through automatically.
# Adding one causes "Provider type mismatch" errors with unit tests.

variable "access_token" {
  type      = string
  sensitive = true
  default   = "placeholder"
}

run "plan_<scenario_name>" {
  command = plan

  variables {
    config_file     = "configurations/<scenario_name>.yaml"
    subscription_id = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = output.azure_values.azure_resource_groups["<key>"] != null
    error_message = "Plan failed — resource group not found."
  }
}
```

**Rules for configuration tests:**
- Test files live **flat** in `tests/` (not in subdirectories) with prefix `integration_config_`.
- **Do NOT add a `provider "rest"` block** — it conflicts with unit tests (see `.github/instructions/testing.instructions.md`).
- Run with: `terraform test -filter=tests/integration_config_<scenario_name>.tftest.hcl`
- All tests must pass as part of the full `terraform test` suite.

#### Step B.7 — Run the full lifecycle test

After implementation, run the configuration test end-to-end against a real Azure subscription:

```bash
export TF_VAR_access_token=$(az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)
export TF_VAR_subscription_id=$(az account show --query id -o tsv)
export TF_VAR_tenant_id=$(az account show --query tenantId -o tsv)
terraform init -backend=false
terraform test -filter=tests/integration_config_<scenario_name>.tftest.hcl
```

**All runs must pass — plan, apply, and destroy.** If any phase fails:
1. Read the error message carefully
2. Identify the root cause (common issues: API doesn't support DELETE → use `rest_operation` instead of `rest_resource`; missing polling states; wrong dependency ordering)
3. Apply the fix
4. Re-run the full lifecycle test
5. Repeat until all phases pass

**Do NOT mark the task complete until plan, apply, and destroy all succeed.**

##### Common lifecycle failures and fixes

| Error | Root Cause | Fix |
|---|---|---|
| `Delete API returns 405` / `DeleteNotSupported` | The Azure API has no DELETE operation for this resource (e.g. Key Vault keys on the management plane) | Switch from `rest_resource` to `rest_operation` (which skips delete by default) |
| `Pending state not expected` | ARM returns a provisioning state not in the `pending` list | Add the missing state string to `poll_create.status.pending` or `poll_delete.status.pending` |
| `Resource already exists` on re-apply | `check_existance` not set or idempotency issue | Set `TF_VAR_check_existance=true` or ensure PUT is idempotent |
| `409 StorageAccountAlreadyTaken` / `409 VaultAlreadyExists` | Globally unique name is taken by another subscription | Add `rest_operation.check_name_availability` + `lifecycle.precondition`. See [Pattern #12](../../patterns/rest-provider-patterns.md#12-name-availability-pre-check-for-globally-unique-resources) |
| Destroy hangs or times out | Missing or incorrect `poll_delete` configuration | Add/fix `poll_delete` with the correct `status_locator` and status codes |

#### Example scenario decomposition

**User request**: "implement a storage account with customer-managed encryption key"

**Decomposition**:

| Module | Status | Notes |
|---|---|---|
| `modules/azure/resource_group/` | REUSE | No changes |
| `modules/azure/user_assigned_identity/` | CREATE | Identity for storage → key vault access |
| `modules/azure/key_vault/` | CREATE | Hosts the CMK; RBAC + purge protection |
| `modules/azure/key_vault_key/` | CREATE | RSA key for encryption |
| `modules/azure/role_assignment/` | CREATE | "Key Vault Crypto User" grant |
| `modules/azure/storage_account/` | EXTEND | Add `encryption` properties |

**Dependency chain**:
```
Layer 0: azure_resource_groups
Layer 1: azure_user_assigned_identities (← azure_resource_groups), azure_key_vaults (← azure_resource_groups)
Layer 2: azure_key_vault_keys (← azure_key_vaults), azure_role_assignments (← azure_key_vaults, azure_user_assigned_identities)
Layer 3: azure_storage_accounts (← azure_resource_groups, azure_user_assigned_identities, azure_key_vaults, azure_key_vault_keys)
```

**Lifecycle test**: `tests/integration_config_storage_account_cmk.tftest.hcl` (plan → apply → destroy)

**Configuration YAML** (`configurations/storage_account_cmk.yaml`):
```yaml
azure_resource_groups:
  cmk:
    location: westeurope

azure_user_assigned_identities:
  cmk_sa:
    resource_group_name: ref:azure_resource_groups.cmk.resource_group_name
    location: ref:azure_resource_groups.cmk.location

azure_key_vaults:
  cmk:
    resource_group_name: ref:azure_resource_groups.cmk.resource_group_name
    location: ref:azure_resource_groups.cmk.location
    enable_rbac_authorization: true
    enable_purge_protection: true

azure_key_vault_keys:
  cmk_sa:
    resource_group_name: ref:azure_resource_groups.cmk.resource_group_name
    vault_name: ref:azure_key_vaults.cmk.name
    key_type: RSA
    key_size: 2048

azure_role_assignments:
  cmk_sa_crypto_user:
    scope: ref:azure_key_vaults.cmk.id
    principal_id: ref:azure_user_assigned_identities.cmk_sa.principal_id
    role_definition_name: Key Vault Crypto User

azure_storage_accounts:
  cmk:
    resource_group_name: ref:azure_resource_groups.cmk.resource_group_name
    location: ref:azure_resource_groups.cmk.location
    sku_name: Standard_LRS
    kind: StorageV2
    identity_type: UserAssigned
    identity_user_assigned_identity_ids:
      - ref:azure_user_assigned_identities.cmk_sa.id
    encryption_key_vault_url: ref:azure_key_vaults.cmk.vault_uri
    encryption_key_name: ref:azure_key_vault_keys.cmk_sa.name
    encryption_identity: ref:azure_user_assigned_identities.cmk_sa.id
```

#### Example scenario: "key vault with private endpoint"

**Decomposition** (note: the user only said "key vault" and "private endpoint" — the agent must include all implicit dependencies):

| Module | Status | Notes |
|---|---|---|
| `modules/azure/resource_group/` | REUSE | No changes |
| `modules/azure/virtual_network/` | CREATE | Needed for the subnet |
| `modules/azure/subnet/` | CREATE | Private endpoint requires a subnet |
| `modules/azure/key_vault/` | CREATE | The primary resource |
| `modules/azure/private_endpoint/` | CREATE | Connects key vault to subnet |
| `modules/azure/private_dns_zone/` | CREATE | `privatelink.vaultcore.azure.net` |
| `modules/azure/private_dns_zone_virtual_network_link/` | CREATE | Links DNS zone to VNet |

**Dependency chain**:
```
Layer 0: azure_resource_groups
Layer 1: azure_virtual_networks (← azure_resource_groups), azure_key_vaults (← azure_resource_groups)
Layer 2: subnets (← azure_virtual_networks), azure_private_dns_zones (← azure_resource_groups)
Layer 3: azure_private_endpoints (← subnets, azure_key_vaults), private_dns_zone_virtual_network_links (← azure_private_dns_zones, azure_virtual_networks)
```

**Lifecycle test**: `tests/integration_config_key_vault_private_endpoint.tftest.hcl` (plan → apply → destroy)

## Hero Mode — Scaffolding a Hero-Quality Module

When the user requests a **hero module** (or uses the phrase "hero" alongside the resource name), follow the standard Mode A or Mode B procedure and additionally apply the following criteria on top.

### What is a hero module?

| Criterion | Standard module | Hero module |
|-----------|----------------|-------------|
| **Properties** | Common writable properties | **All** writable properties from the spec exposed as variables |
| **Examples** | `minimum/` + basic `complete/` | Extended `complete/` covering every variable group |
| **Configurations** | 1 config YAML (if any) | **Multiple** `configurations/*.yaml` files showing distinct permutations and scenarios |
| **Variable validation** | No validation rules | `validation` blocks derived from spec constraints (enums, length limits, regex patterns) |

### Additional steps for hero mode (after standard generation)

#### H1 — Full property coverage

Read the full spec for the resource (`azure-specs_read_spec`) and list every writable property. For each property not already in `variables.tf`:
- Add the variable with the correct HCL type, `default = null`, and a `description` quoting the spec description.
- Add it to the `body` in `main.tf`.
- Add it to the `map(object({...}))` in the root `azure_<plural>.tf`.

#### H2 — Variable validation rules

For every variable mapping to a spec property with explicit constraints, add a `validation` block:

| Spec constraint | Terraform validation |
|----------------|----------------------|
| `enum: [a, b, c]` | `condition = contains(["a","b","c"], var.x)` |
| `minLength: N` | `condition = length(var.x) >= N` |
| `maxLength: N` | `condition = length(var.x) <= N` |
| `pattern: "^[a-z]..."` | `condition = can(regex("^[a-z]...", var.x))` |
| `minimum: N` / `maximum: N` | `condition = var.x >= N && var.x <= N` |

Only add validations where the constraint is explicit in the spec. Guard nullable optional variables:
```hcl
validation {
  condition     = var.x == null || length(var.x) <= 24
  error_message = "x must be at most 24 characters."
}
```

#### H3 — Extended complete example

Ensure `examples/azure/<name>/complete/` exercises every variable group:
- `config.yaml.example` contains meaningful example values for every property.
- The example is self-documenting: a reader understands all configuration options without reading the spec.

#### H4 — Multiple configuration files

Create at least **two** `configurations/*.yaml` files demonstrating distinct scenarios (e.g. basic, with encryption, with private endpoint, with RBAC). Each must have a matching `tests/integration_config_<scenario_name>.tftest.hcl` that at minimum runs a plan.

### Hero completion criteria

A module is hero quality when:
- [ ] All writable spec properties are exposed as variables
- [ ] All optional variables have `validation` blocks where the spec defines constraints
- [ ] `complete/` example exercises every variable group
- [ ] At least two `configurations/*.yaml` files exist with distinct scenarios
- [ ] All configuration tests pass (`terraform test`)
- [ ] A plan runs cleanly for every configuration YAML (`./tf.sh plan`)
- [ ] The **Hero Modules** table in `README.md` is updated (see below)

### Updating the Hero Modules table

Once all criteria above are met, add a row to the **Hero Modules** table in `README.md`:

```markdown
| `<module_name>` | Azure | `configurations/<name>_basic.yaml`, `configurations/<name>_<variant>.yaml` | <one-line note> |
```

Remove the placeholder row `*(none yet — ...)` if it is still present.

---

## Conventions

- Module directories use **snake_case**: `modules/azure/resource_group/`, `modules/azure/virtual_network/`
- **Module names must be descriptive and unambiguous.** When the ARM type's last segment is too generic (e.g., `connections`, `endpoints`, `rules`), qualify the module name with the parent resource context. Examples:
  - `Microsoft.Network/connections` → `virtual_network_gateway_connection` (not `connection`)
  - `Microsoft.Network/virtualNetworks/subnets` → `virtual_network_subnet` (not `subnet`)
  - The name should make the purpose obvious without needing to read the module's code
- Examples call the **root module** at `source = "../../../../"` via the plural map variable
- Tests live flat in `tests/` — run with `terraform test` from repo root (see `.github/instructions/testing.instructions.md`)
- Every module **must** have both a unit test (`unit_azure_<name>.tftest.hcl`) and integration test (`integration_azure_<name>.tftest.hcl`)
- Provider: `LaurentLesle/rest ~> 1.0` — never `azurerm`
- **`check_existance`**: Every `rest_resource` block must use `check_existance = var.check_existance` (not hardcoded). Each module must declare a `variable "check_existance" { type = bool; default = false }`. The root module passes `var.check_existance` to all child modules. Set `TF_VAR_check_existance=true` only during brownfield import (tf-import).
- **Name availability pre-check**: For resources with **globally unique names** (storage accounts, key vaults, CIAM directories, etc.), add a `rest_operation.check_name_availability` that calls the ARM `checkNameAvailability` POST API, with a `lifecycle.precondition` on the main resource. Skip when `check_existance = true`. See [Pattern #12](../../patterns/rest-provider-patterns.md#12-name-availability-pre-check-for-globally-unique-resources). Check the Azure REST API spec — if the resource provider has a `checkNameAvailability` operation, it must be wired in.
- **Resource provider registration check**: Every module **must** include a `data "rest_resource" "provider_check"` that GETs the provider registration status at plan time, and a `lifecycle { precondition }` on the main resource that fails with a YAML remediation hint if the provider is not registered. The error message must show the YAML to add (not a CLI command). Template:
  ```hcl
  data "rest_resource" "provider_check" {
    id = "/subscriptions/${var.subscription_id}/providers/<Namespace>"
    query = { api-version = ["2025-04-01"] }
    output_attrs = toset(["registrationState"])
  }
  ```
  And on the main `rest_resource`:
  ```hcl
  lifecycle {
    precondition {
      condition     = data.rest_resource.provider_check.output.registrationState == "Registered"
      error_message = "Resource provider <Namespace> is not registered on subscription ${var.subscription_id}. Add to your config YAML:\n\n  azure_resource_provider_registrations:\n    <short_name>:\n      resource_provider_namespace: <Namespace>"
    }
  }
  ```
  Where `<Namespace>` is the ARM provider (e.g. `Microsoft.Network`, `Microsoft.Storage`) and `<short_name>` is a short key (e.g. `network`, `storage`).
- **Permission pre-check (`checkAccess`)**: For resources requiring **elevated or uncommon permissions** (Billing Account Owner, Subscription Owner, cross-tenant operations, PIM-activated roles), add a `rest_operation.check_access` that POSTs to the ARM `checkAccess` API, with `check` blocks (advisory warnings) surfacing actionable guidance. The check is **opt-in** via `var.precheck_access` (default `false`). Use `check` blocks (not `lifecycle.precondition`) because permission issues are advisory — the caller may have just-in-time access. See [Pattern #13](../../patterns/rest-provider-patterns.md#13-permission-pre-check-checkaccess-for-elevated-permission-resources).
- **`output_attrs`**: Every `rest_resource` block must include `output_attrs = toset([...])` listing only gjson paths used by `outputs.tf`. Always include `"properties.provisioningState"`. See [Pattern #2](../../patterns/rest-provider-patterns.md#2-output_attrs--controlling-output-state-size).
- **Output access**: Always use direct attribute access (`rest_resource.*.output.properties.foo`), never `jsondecode()`. See [Pattern #4](../../patterns/rest-provider-patterns.md#4-output-access-pattern--direct-vs-jsondecode).
- Configuration YAML files live in `configurations/` with descriptive names (e.g. `storage_account_cmk.yaml`, `key_vault_private_endpoint.yaml`)
- The `ref:` syntax in YAML wires cross-resource dependencies resolved at plan time by `azure_config.tf`
- **`externals`**: Use the `externals` top-level YAML key to declare static attributes for resources not managed by Terraform (e.g. manually-created tenants, existing resource groups, GitHub organizations). Available at Layer 0 via `ref:externals.<category>.<key>.<attr>`. See [Pattern #8](../../patterns/rest-provider-patterns.md#8-external-references-externals--static-data-in-ref-context).
  > **CI impact**: any config with a top-level `externals:` block is **automatically excluded** from the plan-only CI matrix (which uses a placeholder token). It will only be validated by the `apply-tests` job on push to `main` (real OIDC token). This is intentional — `externals` entries resolve via live ARM/Graph calls that fail with 401/403 on a placeholder token.
- Every configuration YAML **must** include a `terraform_backend` block immediately after the header comment. Use `type: local` for local execution:
  ```yaml
  # ── State backend ────────────────────────────────────────────────────────────
  terraform_backend:
    type: local
    path: <scenario_name>.tfstate
  ```
  The `path` value is `<scenario_name>.tfstate` where `<scenario_name>` matches the filename without extension. This ensures state is always isolated per configuration.
- **`subscription_id`**: Every config that deploys Azure resources must supply `subscription_id`. Either embed it inline in the YAML (use `"00000000-0000-0000-0000-000000000000"` for demos) or rely on `TF_VAR_subscription_id`. CI sets this env var to the placeholder UUID in plan-only jobs and to the real subscription in apply jobs. Omitting it entirely causes `var.subscription_id is null` at plan time.
- **`# ci:requires-live-token` marker**: If a config performs live ARM calls at plan time for reasons other than `externals:` (e.g. it was auto-generated by `/tf-import` and uses `check_existance: true` on resources), add `# ci:requires-live-token` to the header comment. CI will exclude it from the plan-only matrix just like `externals:` configs:
  ```yaml
  # Auto-generated by tf-import from subscription <id>
  # ci:requires-live-token
  # (check_existance: true causes plan-time GET calls that fail with a placeholder token)
  ```
  See `configurations/README.md` for the full rule set.
- Every configuration YAML **must** have a corresponding test in `tests/` (prefixed with `integration_config_`) that validates at minimum a plan
- **Destroy must always succeed.** Resources that don't support DELETE (e.g. Key Vault management-plane keys) must use `rest_operation` instead of `rest_resource`
- A configuration is not considered complete until `terraform test` passes

### Plan-time output pattern

All sub-module outputs that can be derived from input variables **must** echo the input directly (not the API response). This ensures `path`, `id`, `name`, `location`, `vault_uri`, etc. are known at plan time.

```hcl
# outputs.tf — plan-time known (echoes input)
output "id" {
  value = local.kv_path  # built from var.subscription_id, var.resource_group_name, var.vault_name
}
output "name" {
  value = var.vault_name
}
output "vault_uri" {
  value = "https://${var.vault_name}.vault.azure.net/"
}

# outputs.tf — known after apply (Azure-assigned)
output "provisioning_state" {
  value = try(rest_resource.key_vault.output.properties.provisioningState, null)
}
```

### Explicit `depends_on` for layer ordering

Because sub-module outputs are plan-time known, Terraform cannot infer cross-module dependencies from data flow. Each root module block **must** include `depends_on` referencing modules from the previous layer:

| Layer | Resources | `depends_on` |
|-------|-----------|-------------|
| 0 | `azure_resource_groups` | *(none)* |
| 1 | `azure_key_vaults`, `azure_user_assigned_identities` | `[module.azure_resource_groups]` |
| 2 | `azure_key_vault_keys`, `azure_role_assignments` | `[module.azure_key_vaults, module.azure_user_assigned_identities]` |
| N | `azure_storage_accounts` | `[module.azure_key_vault_keys, module.azure_role_assignments]` |

### Naming convention

The root module does **not** include a naming module. Resource names are always required inputs. The `Azure/naming/azurerm` module can be used in example wrappers (see `examples/azure/with_naming/`) or by the caller.

## See Also

- Patterns: [`.github/patterns/rest-provider-patterns.md`](../../patterns/rest-provider-patterns.md) — accumulated patterns for output_attrs, output access, ARM body defaults, and import body specificity
- Azure agent: [`.github/agents/azure-rest-module.agent.md`](../../agents/azure-rest-module.agent.md)
- Entra ID agent: [`.github/agents/entraid-graph-module.agent.md`](../../agents/entraid-graph-module.agent.md)
- Test task: `tf-test: <resource_name> apply+destroy` (VS Code task)

---

### Mode C — Entra ID resource module

For resources backed by the **Microsoft Graph API** (applications, service principals, groups, etc.), invoke the **Entra ID Graph Module Generator** agent:

```
@Entra ID Graph Module Generator <resource type>
```

Examples:
```
@Entra ID Graph Module Generator Application
@Entra ID Graph Module Generator Service Principal
```

The agent will:
1. Locate the Microsoft Graph API spec via `msgraph-specs` MCP tools
2. Parse the POST/PATCH/DELETE paths and writable/read-only properties
3. Generate `modules/entraid/<resource_name>/` (versions.tf, variables.tf, main.tf, outputs.tf, README.md)
4. Update the root module — add `entraid_<plural_resource_name>.tf` and append to `entraid_outputs.tf`
5. Generate `examples/entraid/<resource_name>/minimum/` and `examples/entraid/<resource_name>/complete/`
6. Generate tests:
   - `tests/unit_entraid_<resource_name>.tftest.hcl` — sub-module isolation (plan only, Graph `base_url`, own provider block)
   - `tests/integration_entraid_<resource_name>.tftest.hcl` — root module test (no provider block)
7. Run `terraform fmt` and `terraform validate`

#### Key differences from Azure ARM (Mode A)

| Aspect | Azure ARM (Mode A) | Entra ID (Mode C) |
|---|---|---|
| API | Azure Resource Manager | Microsoft Graph v1.0 |
| Provider alias | `rest` (default) | `rest.graph` |
| Create method | PUT (client-specified ID) | POST (server-assigned ID) |
| Update method | PUT | PATCH |
| ID handling | Deterministic path `var.subscription_id/...` | Server-assigned `$(body.id)` |
| Polling | `poll_create`/`poll_delete` for async | `poll_create` with `code` status_locator (30s, see agent doc) |
| `check_existance` | Required | Not used |
| Root file prefix | `azure_` | `entraid_` |
| Module directory | `modules/azure/` | `modules/entraid/` |
| Test directory | `tests/` (flat, prefix `unit_azure_` / `integration_azure_`) | `tests/` (flat, prefix `unit_entraid_` / `integration_entraid_`) |
| Example directory | `examples/azure/` | `examples/entraid/` |
| Output name | `output "values"` | `output "entraid_values"` |
| Layer context | `_ctx_l0`, `_ctx_l0b`, `_ctx_l1` … | `_entraid_ctx_l0`, `_entraid_ctx_l1` … |
| Layer resolution base | Applications resolve against `_ctx_l0b` (Azure base) | L1 Entra ID resources resolve against `_entraid_ctx_l0` |

---

### Mode D — GitHub REST API resource module

For resources backed by the **GitHub REST API** (repositories, environments, secrets, variables, teams), invoke the **GitHub Rest Module Generator** agent:

```
@GitHub Rest Module Generator <resource type>
```

Examples:
```
@GitHub Rest Module Generator Repository
@GitHub Rest Module Generator Environment
@GitHub Rest Module Generator Organization Secret
```

The agent will:
1. Locate the GitHub REST API spec via `github-specs` MCP tools
2. Parse the POST/PUT/PATCH/GET/DELETE paths and writable/read-only properties
3. Generate `modules/github/<resource_name>/` (versions.tf, variables.tf, main.tf, outputs.tf, README.md)
4. Update the root module — add `github_<plural_resource_name>.tf` and append to `github_outputs.tf`
5. Generate `examples/github/<resource_name>/minimum/` and `examples/github/<resource_name>/complete/`
6. Generate tests:
   - `tests/unit_github_<resource_name>.tftest.hcl` — sub-module isolation (plan only, own provider block)
   - `tests/integration_github_<resource_name>.tftest.hcl` — root module test (no provider block)
7. Run `terraform fmt` and `terraform validate`

#### Key differences from Azure ARM (Mode A)

| Aspect | Azure ARM (Mode A) | GitHub REST (Mode D) |
|---|---|---|
| API | Azure Resource Manager | GitHub REST API v3 |
| Provider alias | `rest` (default) | `rest.github` (declared in `azure_provider.tf`) |
| Base URL | `https://management.azure.com` | `https://api.github.com` |
| Create method | PUT (idempotent) | POST (collection) or PUT (resource) — depends on endpoint |
| Auth | Bearer token / OAuth2 refresh | `Bearer ${var.github_token}` + `X-GitHub-Api-Version` header |
| Polling | `poll_create`/`poll_delete` for async LRO | `poll_create` with `status_locator = "code"` for POST-to-collection eventual consistency |
| `check_existance` | Used for PUT-scoped resources | Only for PUT-created resources (environments, branch protection); NOT for POST-to-collection (repos, teams) |
| Secrets encryption | N/A | `provider::rest::nacl_seal()` with org/repo public key |
| Root file prefix | `azure_` | `github_` |
| Module directory | `modules/azure/` | `modules/github/` |
| Layer system | L0–LN based on ARM dependency chain | L4 = repos/org secrets/org variables, L5 = environments/repo secrets/repo variables |
| Output name | `output "azure_values"` | `output "github_values"` |

#### GitHub-specific patterns

- **POST-to-collection eventual consistency** — GitHub POST-create operations (repos, teams) return 201 immediately, but GET can 404 for several seconds. Use `poll_create` with `status_locator = "code"`, `success = "200"`, `pending = ["404"]`.
- **`check_existance` limitation** — POST-to-collection resources cannot use `check_existance` because the provider would GET the collection (always 200), not the individual resource.
- **NaCl sealed-box encryption** — GitHub secrets must be encrypted with the repo/org public key using `provider::rest::nacl_seal(key, plaintext)`.
- **`X-GitHub-Api-Version` header** — Required on all requests; set via `header` in the provider or module.

See full details in [`.github/agents/github-rest-module.agent.md`](../../agents/github-rest-module.agent.md).
