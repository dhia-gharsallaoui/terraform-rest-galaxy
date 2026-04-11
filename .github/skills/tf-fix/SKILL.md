---
name: tf-fix
description: "Audit and fix existing Terraform modules against the Azure REST API spec. Use when: module drift, fix module, update api version, missing property, missing output, fix polling, fix test, tf_fix, audit module, sync spec, gap analysis, reconcile module, update module from spec, fix storage_account, fix resource_group, module out of date, spec drift, missing pending state, promote to hero, hero module, hero quality, full property coverage, add validation rules"
argument-hint: "Module name to audit (e.g. 'resource_group', 'storage_account') or 'all' for every module"
---

# tf-fix

Audit one or more Terraform modules against the Azure REST API specification, identify gaps, apply fixes, and confirm with tests.

## When to Use

- A module's API version is outdated and you want to sync to the latest stable spec
- ARM returns unexpected states (e.g. `ResolvingDns`) not in the polling `pending` list
- The spec has new writable properties that are missing from `variables.tf` / `body`
- Read-only outputs from the spec are not exposed in `azure_outputs.tf`
- Tests fail due to structural mismatches (wrong output paths, missing variables, wrong assertions)
- Root module wiring (`azure_<plural>.tf`, `config.tf`, `azure_outputs.tf`) is out of sync with sub-modules
- Example configurations don't match the current module surface area
- You want a full gap analysis report before making changes
- **You want to promote a module to hero quality** (see Hero Mode below)

## Source of Truth

The **Azure Rest Module Generator** agent definition at `.github/agents/azure-rest-module.agent.md` defines the canonical structure for every module. All auditing checks are derived from that specification.

## Procedure

### Step 0 — Determine scope

Parse the argument:
- A specific module name (e.g. `resource_group`, `storage_account`) → audit only that module
- `all` or no argument → audit every directory under `modules/azure/`

List the target modules:
```
ls modules/azure/
```

### Step 1 — Fetch the current spec for each module

For **each** target module, read the module's `main.tf` header comment to find the `spec_path` and `api_version`:

```hcl
# Source: azure-rest-api-specs
#   spec_path : <spec_path>
#   api_version: <current_version>
```

If the header comment is missing, fall back to keyword search:
```
azure-specs_find_resource(keyword="<resource keyword from module name>")
```
Pick the matching `spec_path` (control plane → `resource-manager`, data plane → `data-plane`).

Then call the `azure-specs` MCP tools to get the latest version and spec summary:

```
azure-specs_latest_stable_version(spec_path="<spec_path>")   → latest_version + stability
azure-specs_get_spec_summary(spec_path="<spec_path>", version="<latest_version>")
```

The `latest_stable_version` tool automatically falls back to the latest preview if no stable version exists — check the returned `stability` field (`"stable"` or `"preview"`).

If you need the complete version history, also call:
```
azure-specs_list_api_versions(spec_path="<spec_path>")   → all versions (stable + preview, newest first)
```

**Version drift rules:**
- If `latest_version` differs from `current_version`, flag as **API version drift**.
- If `stability` is `"preview"` and the module currently uses a preview version, check if there is a newer preview available.
- If `stability` is `"preview"` and the module currently uses a stable version, do NOT downgrade to preview — flag as **preview-only (no stable)** and report it, but keep the current stable version unless the user explicitly opts in.
- If `stability` is `"stable"` and the module currently uses a preview version, flag as **stable now available** — upgrading from preview to stable is recommended.

### Step 2 — Audit files against the agent specification

For each module, read all files and compare against the rules defined in `.github/agents/azure-rest-module.agent.md`. Check every layer:

#### 2a. Sub-module (`modules/azure/<name>/`)

| Check | What to verify |
|-------|---------------|
| **API version** | `local.api_version` matches latest stable from spec (or latest preview if no stable exists) |
| **Path** | Resource path matches the PUT path from spec (correct casing, segments) |
| **Writable properties** | Every writable property from the spec has a corresponding variable in `variables.tf` and is included in the `body` in `main.tf` |
| **Read-only properties** | Every read-only property from the spec is exposed as an output in `azure_outputs.tf` |
| **Polling config** | `poll_create`, `poll_update`, `poll_delete` match the spec's LRO pattern (async vs sync, correct `status_locator`, correct `url_locator`, all observed `pending` states) |
| **check_existance** | `check_existance = var.check_existance` is used in `rest_resource` blocks (GET before PUT; adopts existing). The variable defaults to `false`; set to `true` via `TF_VAR_check_existance=true` only during brownfield import workflows (tf-import). Must NOT be hardcoded to `true` on globally-unique resources (key vaults, storage accounts) where 409 could mean name taken by another tenant or soft-deleted |
| **Variable types** | JSON→HCL type mapping is correct (`string→string`, `integer→number`, `boolean→bool`, `object→map(any)`, `array→list(any)`) |
| **Variable defaults** | Required spec fields have no `default`; optional fields have `default = null` |
| **Name variable** | `<resource_name_var>` is required (string) — names must be explicitly provided |
| **versions.tf** | `required_version >= 1.5.0`, rest `~> 0.1` |
| **Plan-time outputs** | Outputs derivable from inputs (`id`, `name`, `location`, `vault_uri`) echo input variables, not `rest_resource.*.output.*` |
| **API-sourced outputs** | Outputs truly assigned by Azure (`principal_id`, `provisioning_state`, endpoints) source from `rest_resource.*.output.*` using **direct attribute access** (not `jsondecode`) — see [Pattern #4](../../patterns/rest-provider-patterns.md#4-output-access-pattern--direct-vs-jsondecode) |
| **output_attrs** | Every `rest_resource` block has `output_attrs = toset([...])` whitelisting only the gjson paths needed by `outputs.tf`. Always includes `"properties.provisioningState"` — see [Pattern #2](../../patterns/rest-provider-patterns.md#2-output_attrs--controlling-output-state-size) |
| **Writable collection defaults** | Resources with ARM-initialized collection properties (e.g., rule collections on firewalls) include them in body with default-empty variables — see [Pattern #6](../../patterns/rest-provider-patterns.md#6-arm-body-defaults-for-writable-collection-properties) |
| **Name availability pre-check** | Globally unique resources (storage accounts, key vaults, CIAM directories, etc.) must include a `rest_operation.check_name_availability` that POSTs to the ARM `checkNameAvailability` endpoint **at plan time**, plus a `lifecycle.precondition` on the main resource that fails with a clear message when the name is taken. Use `azure-specs_read_spec` to find the correct endpoint. Skip for resources without a `checkNameAvailability` API. — see [Pattern #12](../../patterns/rest-provider-patterns.md#12-name-availability-pre-check-for-globally-unique-resources) |
| **Resource provider registration check** | Every module must have a `data "rest_resource" "provider_check"` that GETs `/subscriptions/${var.subscription_id}/providers/<Namespace>?api-version=2025-04-01` with `output_attrs = toset(["registrationState"])`, and a `lifecycle { precondition }` on the main resource checking `registrationState == "Registered"`. The error message must show the YAML to add (`azure_resource_provider_registrations`), not a CLI command. See tf-module conventions. |
| **Permission pre-check (`checkAccess`)** | For modules requiring elevated or uncommon permissions (billing, subscription, cross-tenant), verify a `rest_operation.check_access` with `var.precheck_access` opt-in and `check` blocks (advisory warnings) exist. See [Pattern #13](../../patterns/rest-provider-patterns.md#13-permission-pre-check-checkaccess-for-elevated-permission-resources). |
| **Immutable properties (`force_new_attrs`)** | If the Azure spec marks properties as `x-ms-mutability: ["create", "read"]` (no `"update"`), or if an update returns 400 with `*UpdateNotPermitted`/`*CannotBeChanged`, verify the module has `force_new_attrs = toset([...])` listing those paths. Common: `properties.principalId` on role assignments, `properties.issuer`/`properties.subject` on FICs. See [Pattern #19](../../patterns/rest-provider-patterns.md#19-force_new_attrs--immutable-body-properties). |

#### 2b. Root module wiring

| Check | What to verify |
|-------|---------------|
| **`azure_<plural>.tf`** | Variable `type = map(object({...}))` has attributes matching every sub-module variable; module block passes all attributes; `for_each` references `local.<plural>` (not `var.<plural>`) |
| **`depends_on`** | Module block includes `depends_on` referencing all modules from the preceding dependency layer (Layer 0 has none; Layer 1 depends on `module.azure_resource_groups`; etc.) |
| **`azure_config.tf`** | `local.<plural>` = merge of YAML config and direct variable; ref-resolution context uses module outputs (plan-time known via input-echo pattern) |
| **`azure_outputs.tf`** | `output "values"` map includes `<plural> = module.<plural>` |
| **`azure_<plural>.tf`** | Variable `type = map(object({...}))` has attributes matching every sub-module variable; module block passes all attributes; `for_each` references `local.<plural>` (not `var.<plural>`) |

#### 2f. Configuration YAML files (`configurations/*.yaml`)

For every configuration YAML that corresponds to the module under audit (or for all configs when scope is `all`):

| Check | What to verify |
|-------|---------------|
| **`terraform_backend` present** | File contains a `terraform_backend:` block immediately after the header comment |
| **`type: local` for local execution** | Default type is `local` with `path: <scenario_name>.tfstate` unless a remote backend has been deliberately configured |
| **Key uniqueness** | `path` / `key` value is unique — no two configs share the same state file path |

#### 2c. Examples (`examples/azure/<name>/minimum/` and `examples/azure/<name>/complete/`)

| Check | What to verify |
|-------|---------------|
| **`main.tf`** | Calls root module at `source = "../../../../"`, not sub-module |
| **`variables.tf`** | Declares all required vars (minimum) or all vars (complete) |
| **`outputs.tf`** | Re-exports `module.root.values.<plural>` |
| **`config.yaml.example`** | Matches the variable surface area, uses placeholder values |

#### 2d. Unit tests (`tests/unit_azure_<name>.tftest.hcl`)

| Check | What to verify |
|-------|---------------|
| **Provider block** | Has its own `provider "rest"` block with `base_url` and placeholder token |
| **Module source** | Uses `module { source = "./modules/azure/<name>" }` |
| **Command** | `command = plan` only |
| **Assertions** | Only asserts plan-time-known outputs (id, name, location — not `rest_resource.*.output.*`) |
| **Variables** | Only declares variables the module actually has (no undeclared variables) |

#### 2e. Integration tests (`tests/integration_azure_<name>.tftest.hcl`)

| Check | What to verify |
|-------|---------------|
| **No provider block** | Must NOT have a `provider "rest"` block (causes type mismatch with unit tests) |
| **Output references** | `output.azure_values.azure_<plural>["key"].<attr>` |
| **Cross-run references** | `run.<name>.azure_values.azure_<plural>["key"].<attr>` |
| **Variables per run** | Each `run` block declares all needed variables independently (parent resources included) |
| **No `command = destroy`** | Only `apply` and `plan` are valid |
| **Idempotency test** | Second apply asserts same `id` |
| **Child resource prereqs** | Tests for child resources include parent resource variables (e.g. `azure_resource_groups` for storage accounts) |

### Step 3 — Report gaps

Print a gap report in this format:

```
## Gap Report: <module_name>

### API Version
- Current: <current_version>
- Latest: <latest_version> (<stability: stable|preview>)
- Status: ✅ current | ⚠️ drift | ⚠️ preview-only (no stable) | ✅ stable now available

### Sub-module (modules/azure/<name>/)
- [ ] <description of gap>
- [x] <check that passed>

### Root Module Wiring
- [ ] <description of gap>

### Examples
- [ ] <description of gap>

### Tests
- [ ] <description of gap>

### Summary: <N> gaps found
```

### Step 4 — Apply fixes

For each gap identified, apply the fix following the conventions in the agent specification:

1. **API version drift** → Update `local.api_version` in `main.tf`, update header comment (including `# stability: preview` if applicable), adjust body/variables/outputs for any schema changes
2. **Missing writable property** → Add variable to `variables.tf`, add to `body` in `main.tf`, add to `map(object)` in root `azure_<plural>.tf`
3. **Missing read-only output** → Add output to sub-module `azure_outputs.tf`
4. **Polling state missing** → Add the state string to the correct `pending` list
5. **Test structural issue** → Fix output paths, add missing variables, fix cross-run references
6. **Root wiring gap** → Update `azure_<plural>.tf`, `config.tf`, or `azure_outputs.tf`
7. **Example drift** → Update variables, outputs, or config.yaml.example
8. **Missing name availability check** → Add `rest_operation.check_name_availability` with a POST to the ARM `checkNameAvailability` endpoint, add a `lifecycle.precondition` on the main `rest_resource`, and add necessary variables (`subscription_id`) — see [Pattern #12](../../patterns/rest-provider-patterns.md#12-name-availability-pre-check-for-globally-unique-resources)
9. **Missing resource provider registration check** → Add `data "rest_resource" "provider_check"` that GETs `/subscriptions/${var.subscription_id}/providers/<Namespace>?api-version=2025-04-01` with `output_attrs = toset(["registrationState"])`. Add a `lifecycle { precondition }` on the main `rest_resource` checking `registrationState == "Registered"`. The error message must show the YAML snippet to add, not a CLI command:
10. **Missing permission pre-check** → For elevated-permission resources (billing, subscription, cross-tenant), add `rest_operation.check_access` with `var.precheck_access` opt-in and `check` blocks (advisory). See [Pattern #13](../../patterns/rest-provider-patterns.md#13-permission-pre-check-checkaccess-for-elevated-permission-resources)
   ```
   error_message = "Resource provider <Namespace> is not registered on subscription ${var.subscription_id}. Add to your config YAML:\n\n  azure_resource_provider_registrations:\n    <short_name>:\n      resource_provider_namespace: <Namespace>"
   ```
11. **Missing `terraform_backend` in configuration YAML** → Insert a `terraform_backend` block immediately after the header comment:
    ```yaml
    # ── State backend ────────────────────────────────────────────────────────────
    terraform_backend:
      type: local
      path: <scenario_name>.tfstate
    ```
    Use `<scenario_name>` = filename without extension. Confirm the path is unique across all configurations.
12. **Missing `force_new_attrs`** → For immutable properties (spec `x-ms-mutability: ["create", "read"]` or 400 `*UpdateNotPermitted`), add `force_new_attrs = toset(["properties.<field>"])`. See [Pattern #19](../../patterns/rest-provider-patterns.md#19-force_new_attrs--immutable-body-properties).

After each fix, run `terraform fmt -recursive` on affected directories.

### Step 5 — Validate

Run static validation from the repo root:

```bash
terraform fmt -recursive .
terraform validate
```

Fix any errors before proceeding.

### Step 5b — Plan configuration files

For every configuration YAML in `configurations/` that uses the module under audit (or all configs when scope is `all`), run a real plan using `./tf.sh`:

```bash
./tf.sh plan configurations/<scenario_name>.yaml
```

This validates that the configuration produces a clean plan end-to-end — provider resolution, ref wiring, body construction, and precondition checks. A clean `terraform validate` is necessary but not sufficient; plan-time errors (type mismatches in locals, missing attributes, precondition failures) only surface here.

**Pass criteria:** `terraform plan` exits 0 with the expected resources in the plan. No errors, no unexpected changes.

If a plan fails:
1. Read the error — it is almost always precise about file, line, and expression
2. Common plan-time failures and fixes:

| Error | Root cause | Fix |
|---|---|---|
| `Unsupported attribute` on `each.value.X` | YAML doesn't set field `X`; module wiring uses `.X` instead of `try(.X, fallback)` | Change root wiring to `try(each.value.X, fallback)` |
| `Inconsistent conditional result types` | Polymorphic ternary branches have different object shapes | Use `jsondecode(jsonencode({...}))` to coerce each branch to `any` before passing to `merge()` |
| `Resource precondition failed` — backend_safety | `terraform_backend.resource_group_name` is empty string (local backend), matching all RG keys via `try(v.resource_group_name, "")` | Guard with `!= ""` before comparing: `try(local._terraform_backend.resource_group_name, "") != ""` |
| `Missing terraform_backend` | Config has no state block | Add `terraform_backend: type: local` — see fix #11 |
| Precondition failed — provider not registered | The ARM provider isn't registered in the test subscription | Register the provider or adjust test variables | 

After fixing plan errors, re-run `terraform validate` and `./tf.sh plan` to confirm both pass.

### Step 6 — Run tests

Run the full test suite using the VS Code task:

```
Task: "terraform test: all"
```

Or manually:
```bash
export TF_VAR_access_token=$(az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)
export TF_VAR_subscription_id=$(az account show --query id -o tsv)
export TF_VAR_resource_group_name=test-rg-rest-tftest
az group create --name $TF_VAR_resource_group_name --location westeurope --subscription $TF_VAR_subscription_id -o table
terraform init -backend=false && terraform test
```

**All runs must pass.** If any test fails:
1. Read the error message
2. Identify the root cause (often a gap missed in Step 2)
3. Apply the fix
4. Re-run tests
5. Repeat until all pass

Do NOT mark the task complete until `terraform test` reports 0 failures (excluding expected auth failures on apply tests).

### Step 7 — Summary

Print a completion summary:

```
## tf-fix: <module_name>

- Gaps found: <N>
- Gaps fixed: <N>
- API version: <old> → <new> (or "unchanged")
- Files modified:
  - <list of files>
- Test result: <N> passed, 0 failed
```

## Common Gap Patterns

These are recurring issues discovered during development of this repo:

| Pattern | Symptom | Fix |
|---------|---------|-----|
| Missing ARM polling state | `Error: unexpected status "<State>"` | Add the state to `pending` list in `poll_create`/`poll_update` |
| Wrong output path in tests | `Reference to undeclared output value` | Change `output.X` to `output.values.X` |
| Missing parent resource in test run | `Error: No value for required variable` | Add parent resource variable block to every `run` |
| Location mismatch across runs | `InvalidResourceLocation` 409 | Use `ref:` or consistent hardcoded values across all runs |
| Read-only property in body | `Error: invalid property` or silent rejection | Remove from `body`, add to `azure_outputs.tf` |
| Stale API version | New properties not available, deprecated warnings | Update `local.api_version` and re-audit schema. If no stable version exists, use latest preview and note in header comment (`# stability: preview`) |
| Output not plan-time known | `path = (known after apply)` for resources whose path should be deterministic | Change output to echo input variable (e.g. `value = var.vault_name`) instead of `rest_resource.*.output.*` |
| Missing `depends_on` | `ResourceGroupNotFound` or similar 404 on create — sibling resources race | Add `depends_on = [module.<previous_layer>]` to the module block |
| Missing `output_attrs` | State file bloat, output drift after import, large plan diffs on `.output` | Add `output_attrs = toset([...])` listing only paths used by `outputs.tf` — see [Pattern #2](../../patterns/rest-provider-patterns.md#2-output_attrs--controlling-output-state-size) |
| `jsondecode` in outputs | Unnecessary `jsondecode(rest_resource.*.output)` wrapper | Replace with direct attribute access: `rest_resource.*.output.properties.foo` — see [Pattern #4](../../patterns/rest-provider-patterns.md#4-output-access-pattern--direct-vs-jsondecode) |
| Import body too broad | `properties = null` in import block imports all read-only fields | Expand to list only writable sub-properties — see [Pattern #1](../../patterns/rest-provider-patterns.md#1-import-body-specificity) |
| Missing writable collection defaults | ARM returns empty arrays for collection properties not in body | Add variables with `default = []` and include in body — see [Pattern #6](../../patterns/rest-provider-patterns.md#6-arm-body-defaults-for-writable-collection-properties) |
| Missing name availability check | `StorageAccountAlreadyTaken`, `VaultAlreadyExists`, or similar 409 after long apply | Add `rest_operation.check_name_availability` + `lifecycle.precondition` — see [Pattern #12](../../patterns/rest-provider-patterns.md#12-name-availability-pre-check-for-globally-unique-resources) |
| Missing provider registration check | Module creates resource without checking if the ARM provider is registered, leading to opaque 4xx errors | Add `data "rest_resource" "provider_check"` + `lifecycle.precondition` — see tf-module conventions |
| Missing permission pre-check | Elevated-permission resource (billing, subscription, cross-tenant) fails with opaque 403/401 at apply time | Add `rest_operation.check_access` + `check` blocks (advisory) with `var.precheck_access` opt-in — see [Pattern #13](../../patterns/rest-provider-patterns.md#13-permission-pre-check-checkaccess-for-elevated-permission-resources) |
| `poll_delete` treats 404 as failure | `Error: Polling failure` during destroy after resource is successfully deleted | Change `poll_delete` to `success = "404"`, `pending = ["200", "202"]` — see [Pattern #15](../../patterns/rest-provider-patterns.md#15-arm-poll_delete--404-means-success) |
| K8s namespace label drift | 3 namespaces show "will be updated" on every plan (removing `kubernetes.io/metadata.name` label) | Include auto-injected label in body: `merge({"kubernetes.io/metadata.name" = var.name}, var.labels)` — see [Pattern #16](../../patterns/rest-provider-patterns.md#16-kubernetes-server-side-mutations--preventing-body-drift) |
| K8s destroy 403 `system:anonymous` | `ephemeral_header` not available during Delete — K8s resources can't authenticate for deletion | Switch to `header` (not `ephemeral_header`) + track token expiry to prevent drift — see [Pattern #14](../../patterns/rest-provider-patterns.md#14-ephemeral_header--not-available-during-delete) and [Pattern #17](../../patterns/rest-provider-patterns.md#17-token-expiry-tracking--preventing-auth-header-drift) |
| Missing `terraform_backend` in config YAML | `terraform init` prompts for backend or defaults to a shared local path; no state isolation between configs | Add `terraform_backend: type: local` block after the header comment — see fix #11 above |
| Immutable property update rejected | `400 RoleAssignmentUpdateNotPermitted` or `400 *CannotBeChanged` on apply after a property value change | Add `force_new_attrs = toset(["properties.<field>"])` to the `rest_resource` block — see [Pattern #19](../../patterns/rest-provider-patterns.md#19-force_new_attrs--immutable-body-properties) |
| Concurrent write 409 on apply | `409 Concurrent*` when creating multiple child resources on the same parent (e.g. FICs on a UAI) | Configure `client.retry` with 409 in `status_codes` on the provider block — see [Pattern #20](../../patterns/rest-provider-patterns.md#20-provider-level-retry-for-transient-errors) |

## Hero Mode — Promoting a Module to Hero Quality

When the user asks to **promote a module to hero quality** (or uses the phrase "hero module"), run the standard audit (Steps 0–7) and additionally enforce the following criteria:

### What is a hero module?

A hero module provides exhaustive coverage of its resource type:

| Criterion | Standard module | Hero module |
|-----------|----------------|-------------|
| **Properties** | Common writable properties | **All** writable properties from the spec exposed as variables |
| **Examples** | `minimum/` only or basic `complete/` | Extended `complete/` covering every variable group; named variants if needed |
| **Configurations** | 0–1 YAML files | **Multiple** `configurations/*.yaml` files showing different permutations and real-world scenarios |
| **Variable validation** | No validation rules | `validation` blocks derived from spec constraints (enums, length limits, regex patterns) |

### Additional hero checks (after Step 2)

#### H1 — Full property coverage

Read the full spec for the resource and list every writable property. For each:
- If the property is missing from `variables.tf`, add it with the correct type, `default = null`, and a `description` quoting the spec description.
- Add it to `body` in `main.tf`.
- Add it to the `map(object({...}))` in the root `azure_<plural>.tf`.

#### H2 — Variable validation rules

For every variable that maps to a spec property with constraints, add a `validation` block:

| Spec constraint | Terraform validation |
|----------------|----------------------|
| `enum: [a, b, c]` | `condition = contains(["a","b","c"], var.x)` |
| `minLength: N` | `condition = length(var.x) >= N` |
| `maxLength: N` | `condition = length(var.x) <= N` |
| `pattern: "^[a-z]..."` | `condition = can(regex("^[a-z]...", var.x))` |
| `minimum: N` / `maximum: N` | `condition = var.x >= N && var.x <= N` |

Only add validations where the constraint is explicit in the spec. Do not invent constraints.

For nullable optional variables (those with `default = null`), guard the validation with a null check:
```hcl
validation {
  condition     = var.x == null || length(var.x) <= 24
  error_message = "x must be at most 24 characters."
}
```

#### H3 — Extended complete example

Update `examples/azure/<name>/complete/` so that:
- Every variable group is exercised (not just required fields).
- `config.yaml.example` contains meaningful example values for every property (use spec examples or sensible defaults).
- The example is self-documenting: a reader should understand all configuration options from the example alone.

#### H4 — Multiple configuration files

Ensure at least **two** `configurations/*.yaml` files exist that exercise the module, each demonstrating a distinct scenario or set of options. For example:
- `configurations/<name>_basic.yaml` — minimal viable deployment
- `configurations/<name>_<variant>.yaml` — advanced scenario (e.g. with encryption, private endpoint, RBAC)

Each configuration file must have a matching `tests/integration_config_<scenario_name>.tftest.hcl` test.

### Hero completion criteria

A module is considered hero quality when:
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

## Constraints

- **Source of truth**: `.github/agents/azure-rest-module.agent.md` — all structural decisions come from this file
- **Spec discovery**: ALWAYS use `azure-specs` MCP tools — never hardcode or guess spec details
- **No provider swap**: Only `LaurentLesle/rest ~> 1.0` — never introduce `azurerm` or `azapi`
- **Tests required**: Every fix MUST be validated with `terraform test` before completion. See `.github/instructions/testing.instructions.md` for test conventions (unit vs integration, naming, provider rules).

## See Also

- Patterns: [`.github/patterns/rest-provider-patterns.md`](../../patterns/rest-provider-patterns.md) — accumulated patterns for import body specificity, output_attrs, output access, ARM body defaults, and drift resolution
- Agent: [`.github/agents/azure-rest-module.agent.md`](../../agents/azure-rest-module.agent.md) — the canonical module specification
- Skill: `tf-module` — creates new modules from scratch (use tf-fix for existing modules)
- Skill: `tf-test` — runs individual example plans (use tf-fix for full audit + test cycle)
