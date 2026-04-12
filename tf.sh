#!/usr/bin/env bash
# ── tf: Terraform wrapper that reads terraform_backend from YAML configs ─────
#
# Usage:
#   ./tf.sh <action> <config_file>
#
# Actions:
#   init      Configure backend + terraform init
#   plan      init + terraform plan
#   apply     init + terraform apply (+ state upload for bootstrap)
#   destroy   init + terraform destroy
#   output    init + terraform output
#   vars      List variables needed for a config (--resolve to show values)
#   status    Show all terraform_backend sections across configs
#
# Examples:
#   ./tf.sh plan configurations/00-bootstrap/config.yaml
#   ./tf.sh apply configurations/00-bootstrap/config.yaml
#   ./tf.sh plan configurations/01-launchpad/config.yaml
#   ./tf.sh status
#
# CI Mode (GitHub Actions):
#   TF_CI_MODE=true TF_VAR_azure_access_token=<token> \
#   TF_VAR_graph_access_token=<token> TF_VAR_subscription_id=<id> \
#   ./tf.sh plan configurations/env-prod/config.yaml
#
# Environment Variables:
#   TF_CI_MODE=true           Enable CI mode (skip az login, use env var tokens)
#   TF_VAR_azure_access_token Azure ARM token (required in CI mode if config uses azure_*)
#   TF_VAR_graph_access_token Microsoft Graph token (required in CI mode if config uses entraid_*)
#   TF_VAR_subscription_id    Azure subscription ID (required in CI mode)
#
# The script:
#   1. Parses terraform_backend from the YAML config
#   2. Rewrites backend.tf to match the backend type
#   3. Acquires Azure tokens (az CLI in dev, env vars in CI mode)
#   4. Runs terraform init with the right -backend-config flags
#   5. Builds -var flags for config_file, remote_state_backend, remote_state_keys
#   6. For bootstrap apply: uploads local state to Azure Storage afterward
#
# Requirements: 
#   Local dev: az CLI, python3 with PyYAML, terraform
#   CI mode: python3 with PyYAML, terraform (az CLI not needed)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
TF_ROOT="$REPO_ROOT/.build"
BACKEND_TF="$TF_ROOT/backend.tf"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

info()  { echo -e "${BLUE}▸${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*" >&2; }
err()   { echo -e "${RED}✗${NC} $*" >&2; }
die()   { err "$@"; exit 1; }

# ── Parse YAML terraform_backend using python3 ──────────────────────────────
# Outputs JSON to stdout. Exits 1 if terraform_backend is missing.
parse_backend() {
  local config_file="$1"
  python3 -c "
import yaml, json, sys
with open('$config_file') as f:
    cfg = yaml.safe_load(f)
tb = cfg.get('terraform_backend')
if not tb:
    print(json.dumps(None))
    sys.exit(0)
print(json.dumps(tb))
"
}

# ── Validate backend configuration ────────────────────────────────────────
# Exits with error if backend is invalid. Called before init.
validate_backend() {
  local backend_json="$1"
  local config_rel="$2"
  
  _TF_BACKEND_JSON="$backend_json" python3 -c '
import json, sys, re, os

backend = json.loads(os.environ["_TF_BACKEND_JSON"])
errors = []

# Check backend type
btype = backend.get("type")
if not btype:
    errors.append("Missing type field in terraform_backend")
elif btype not in ("azurerm", "local", "gcs", "s3"):
    errors.append(f"Unsupported backend type: {btype} (supported: azurerm, local, gcs, s3)")

# Validate azurerm backend
if btype == "azurerm":
    required_fields = ["storage_account_name", "container_name", "key", "resource_group_name"]
    for field in required_fields:
        if not backend.get(field):
            errors.append(f"azurerm backend missing required field: {field}")

    # Validate state key naming convention
    # Flat format: <name>.tfstate  OR  path format: <seg>/<seg>/terraform.tfstate
    key = backend.get("key", "")
    key_pattern = r"^[a-z0-9][a-z0-9_-]*(\.tfstate|(/[a-z0-9_-]+)*/terraform\.tfstate)$"
    if key and not re.match(key_pattern, key):
        errors.append(
            f"Invalid state key format: \"{key}\"\n"
            f"  Expected: <name>.tfstate or <org>/<env>/<workload>/terraform.tfstate\n"
            f"  (segments: lowercase alphanumeric, hyphens, or underscores)"
        )

    # Validate storage account name
    sa_name = backend.get("storage_account_name", "")
    if sa_name and not re.match(r"^[a-z0-9]{3,24}$", sa_name):
        errors.append(
            f"Invalid storage account name: \"{sa_name}\"\n"
            f"  Must be 3-24 chars, lowercase letters and numbers only"
        )

# Report errors
if errors:
    print("\n".join([f"✗ {e}" for e in errors]), file=sys.stderr)
    sys.exit(1)

print("✓ Backend validation passed")
'
}

# ── Detect which token types a config needs ─────────────────────────────────
detect_token_needs() {
  local config_file="$1"
  python3 -c "
import yaml, sys
with open('$config_file') as f:
    cfg = yaml.safe_load(f)
needs = set()
for key in cfg:
    if key.startswith('azure_') or key == 'externals' or key == 'default_location':
        needs.add('arm')
    if key.startswith('entraid_'):
        needs.add('graph')
    if key.startswith('k8s_') or key == 'helm_releases':
        needs.add('k8s')
    if key.startswith('github_'):
        needs.add('github')
print(' '.join(sorted(needs)))
"
}

# ── Extract a JSON field ─────────────────────────────────────────────────────
json_field() {
  local json="$1" field="$2" default="${3:-}"
  python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
val = data.get('$field')
if val is None:
    print('$default')
elif isinstance(val, bool):
    print('true' if val else 'false')
else:
    print(val)
" <<< "$json"
}

# ── Extract remote_states as JSON ────────────────────────────────────────────
json_remote_states() {
  local json="$1"
  python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
rs = data.get('remote_states', {})
if not rs:
    sys.exit(0)
# Build remote_state_keys: { name: key }
keys = {}
for name, cfg in rs.items():
    keys[name] = cfg.get('key', name + '.tfstate')
print(json.dumps(keys, separators=(',', ':')))
" <<< "$json"
}

# ── Extract refresh token from MSAL cache ────────────────────────────────────
extract_refresh_token() {
  python3 -c "
import json, os, sys
cache_path = os.path.expanduser('~/.azure/msal_token_cache.json')
if not os.path.exists(cache_path):
    sys.exit(1)
with open(cache_path) as f:
    cache = json.load(f)
rt_entries = cache.get('RefreshToken', {})
for entry in rt_entries.values():
    if entry.get('client_id') == '04b07795-8ddb-461a-bbee-02f9e1bf7b46':
        print(entry['secret'])
        sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

# ── Acquire tokens ───────────────────────────────────────────────────────────
# In CI mode (TF_CI_MODE=true), tokens are expected to be pre-set in env vars:
#   TF_VAR_azure_access_token
#   TF_VAR_graph_access_token
#   TF_VAR_subscription_id
# Local dev mode acquires tokens via az CLI.
acquire_tokens() {
  local needs="$1"
  local ci_mode="${TF_CI_MODE:-false}"

  if [[ "$needs" == *arm* ]]; then
    if [[ "$ci_mode" == "true" ]]; then
      # CI mode: expect tokens in env vars
      if [[ -z "${TF_VAR_azure_access_token:-}" ]]; then
        die "CI mode: TF_VAR_azure_access_token not set. GitHub Actions should provide OIDC token."
      fi
      if [[ -z "${TF_VAR_subscription_id:-}" ]]; then
        die "CI mode: TF_VAR_subscription_id not set."
      fi
      export TF_VAR_azure_access_token
      export TF_VAR_subscription_id
      ok "ARM token ready (from CI environment)"
    else
      # Local dev: acquire via az CLI
      info "Acquiring ARM token..."
      export TF_VAR_azure_access_token
      TF_VAR_azure_access_token="$(az account get-access-token \
        --resource https://management.azure.com --query accessToken -o tsv)" \
        || die "Failed to acquire ARM token. Run 'az login' first."
      export TF_VAR_subscription_id
      TF_VAR_subscription_id="$(az account show --query id -o tsv)"
      ok "ARM token acquired for subscription $TF_VAR_subscription_id"

      # Extract refresh token for auto-renewal during long operations
      local rt
      rt="$(extract_refresh_token)" || true
      if [[ -n "$rt" ]]; then
        local tenant_id
        tenant_id="$(az account show --query tenantId -o tsv)"
        export TF_VAR_azure_refresh_token="$rt"
        export TF_VAR_azure_token_url="https://login.microsoftonline.com/${tenant_id}/oauth2/v2.0/token"
        ok "Refresh token acquired (tokens will auto-renew)"
      else
        warn "Could not extract refresh token from MSAL cache. Using static access token."
      fi

      # Resolve caller identity for ref:caller.object_id
      info "Resolving caller identity..."
      export TF_VAR_caller_object_id
      TF_VAR_caller_object_id="$(az ad signed-in-user show --query id -o tsv 2>/dev/null)" || true
      if [[ -z "$TF_VAR_caller_object_id" ]]; then
        # Fallback for service principal login
        local sp_app_id
        sp_app_id="$(az account show --query user.name -o tsv 2>/dev/null)" || true
        if [[ -n "$sp_app_id" ]]; then
          TF_VAR_caller_object_id="$(az ad sp show --id "$sp_app_id" --query id -o tsv 2>/dev/null)" || true
        fi
      fi
      if [[ -n "$TF_VAR_caller_object_id" ]]; then
        ok "Caller: $TF_VAR_caller_object_id"
      else
        warn "Could not resolve caller object ID. ref:caller.object_id will be null."
      fi
    fi
  fi

  if [[ "$needs" == *graph* ]]; then
    if [[ "$ci_mode" == "true" ]]; then
      # CI mode: expect token in env var
      if [[ -z "${TF_VAR_graph_access_token:-}" ]]; then
        die "CI mode: TF_VAR_graph_access_token not set. GitHub Actions should provide OIDC token."
      fi
      export TF_VAR_graph_access_token
      ok "Graph token ready (from CI environment)"
    else
      # Local dev: acquire via az CLI
      info "Acquiring Graph token..."
      export TF_VAR_graph_access_token
      TF_VAR_graph_access_token="$(az account get-access-token \
        --resource https://graph.microsoft.com --query accessToken -o tsv)" \
        || die "Failed to acquire Graph token."
      ok "Graph token acquired"

      # Reuse same refresh token for Graph (multi-resource RT)
      if [[ -n "${TF_VAR_azure_refresh_token:-}" ]]; then
        local tenant_id
        tenant_id="$(az account show --query tenantId -o tsv)"
        export TF_VAR_graph_refresh_token="$TF_VAR_azure_refresh_token"
        export TF_VAR_graph_token_url="https://login.microsoftonline.com/${tenant_id}/oauth2/v2.0/token"
      elif rt="$(extract_refresh_token)" && [[ -n "$rt" ]]; then
        local tenant_id
        tenant_id="$(az account show --query tenantId -o tsv)"
        export TF_VAR_graph_refresh_token="$rt"
        export TF_VAR_graph_token_url="https://login.microsoftonline.com/${tenant_id}/oauth2/v2.0/token"
      fi
    fi
  fi

  if [[ "$needs" == *k8s* ]]; then
    info "Checking Docker availability..."
    if docker info >/dev/null 2>&1; then
      export TF_VAR_docker_available=true
      ok "Docker is running"
    else
      export TF_VAR_docker_available=false
      warn "Docker is not running. kind cluster operations will fail."
    fi
  fi
}

# ── Remove K8s-dependent resources from Terraform state ─────────────────────
# When K8s clusters are unreachable, removing these resources from state
# prevents 403 errors during destroy. The underlying K8s objects are cleaned
# up when the kind cluster containers are deleted.
_remove_k8s_from_state() {
  local state_list
  state_list="$(terraform -chdir="$TF_ROOT" state list 2>/dev/null)" || true
  local found=false
  for pattern in "module\\.helm_releases\\." "module\\.k8s_namespaces\\." "module\\.k8s_cluster_role_bindings\\." "module\\.k8s_deployments\\." "module\\.k8s_config_maps\\." "module\\.k8s_service_accounts\\." "ref_token\\."; do
    local resources
    resources="$(echo "$state_list" | grep "^${pattern}" || true)"
    if [[ -n "$resources" ]]; then
      found=true
      while IFS= read -r addr; do
        warn "  Removing from state: $addr"
        terraform -chdir="$TF_ROOT" state rm "$addr" >/dev/null 2>&1 || true
      done <<< "$resources"
    fi
  done
  $found && ok "K8s resources removed from state." || true
}

# ── Extract K8s credentials from existing kind clusters ─────────────────────
extract_k8s_credentials() {
  local config_file="$1"

  # Parse YAML to get k8s_kind_clusters key → name mapping
  local cluster_map
  cluster_map="$(python3 -c "
import yaml, json, sys
with open(sys.argv[1]) as f:
    cfg = yaml.safe_load(f)
clusters = cfg.get('k8s_kind_clusters', {})
result = {}
for key, val in clusters.items():
    if isinstance(val, dict) and 'name' in val:
        result[key] = val['name']
print(json.dumps(result))
" "$config_file")"

  [[ "$cluster_map" != "{}" ]] || return 0

  # Get currently existing kind clusters
  local existing_clusters
  existing_clusters="$(kind get clusters 2>/dev/null)" || return 0
  [[ -n "$existing_clusters" ]] || { info "No existing kind clusters found."; return 1; }

  # Collect credentials into temp file (tokens can be long)
  local tmpfile
  tmpfile="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '$tmpfile'" RETURN
  echo "{}" > "$tmpfile"

  local yaml_key cluster_name
  while IFS='=' read -r yaml_key cluster_name; do
    if echo "$existing_clusters" | grep -qx "$cluster_name"; then
      local context="kind-${cluster_name}"
      info "Extracting credentials for cluster '$cluster_name' (key: $yaml_key)..."

      # Ensure terraform-ref SA exists with cluster-admin
      kubectl create serviceaccount terraform-ref -n kube-system \
        --context "$context" --dry-run=client -o yaml 2>/dev/null | \
        kubectl apply --context "$context" -f - >/dev/null 2>&1 || true

      kubectl create clusterrolebinding terraform-ref-admin \
        --clusterrole=cluster-admin \
        --serviceaccount=kube-system:terraform-ref \
        --context "$context" --dry-run=client -o yaml 2>/dev/null | \
        kubectl apply --context "$context" -f - >/dev/null 2>&1 || true

      # Create a token (1 hour duration)
      local token endpoint
      token="$(kubectl create token terraform-ref -n kube-system \
        --context "$context" --duration=3600s 2>/dev/null)" || true
      endpoint="$(kubectl config view --context "$context" \
        -o jsonpath='{.clusters[?(@.name=="kind-'"$cluster_name"'")].cluster.server}' 2>/dev/null)" || true

      if [[ -n "$token" && -n "$endpoint" ]]; then
        python3 -c "
import json, sys
creds = json.load(open(sys.argv[1]))
creds[sys.argv[2]] = {'endpoint': sys.argv[3], 'token': sys.argv[4]}
json.dump(creds, open(sys.argv[1], 'w'))
" "$tmpfile" "$yaml_key" "$endpoint" "$token"
        ok "Credentials extracted for $cluster_name → $endpoint"
      else
        warn "Failed to extract credentials for $cluster_name (endpoint=${endpoint:-(empty)}, token=${token:+set}${token:-(empty)})"
      fi
    fi
  done < <(python3 -c "
import json, sys
m = json.loads(sys.stdin.read())
for k, v in m.items():
    print(f'{k}={v}')
" <<< "$cluster_map")

  local creds_json
  creds_json="$(cat "$tmpfile")"
  rm -f "$tmpfile"

  if [[ "$creds_json" != "{}" ]]; then
    export TF_VAR_k8s_cluster_credentials="$creds_json"
    ok "K8s cluster credentials set for $(python3 -c "import json,sys; print(', '.join(json.loads(sys.stdin.read()).keys()))" <<< "$creds_json")"
    return 0
  fi

  info "No credentials extracted (kind clusters may not exist yet)."
  return 1
}

# ── Extract AKS cluster credentials ────────────────────────────────────────
# For configs that use both azure_managed_clusters and k8s_* resources,
# extracts AKS API server endpoint and acquires an Azure AD bearer token.
extract_aks_credentials() {
  local config_file="$1"

  # Parse YAML to get cluster_name values from azure_managed_clusters
  local cluster_names
  cluster_names="$(python3 -c "
import yaml, json, sys
with open(sys.argv[1]) as f:
    cfg = yaml.safe_load(f)
clusters = cfg.get('azure_managed_clusters', {})
names = []
for key, val in clusters.items():
    if isinstance(val, dict) and 'cluster_name' in val:
        name = val['cluster_name']
        if not str(name).startswith('ref:'):
            names.append(name)
print(json.dumps(names))
" "$config_file")"

  [[ "$cluster_names" != "[]" ]] || return 0

  # Check if any k8s_ resources reference managed clusters
  local has_k8s
  has_k8s="$(python3 -c "
import yaml, sys
with open(sys.argv[1]) as f:
    cfg = yaml.safe_load(f)
for key in cfg:
    if key.startswith('k8s_') and key != 'k8s_kind_clusters':
        print('yes')
        sys.exit(0)
print('no')
" "$config_file")"

  [[ "$has_k8s" == "yes" ]] || return 0

  info "Extracting AKS cluster credentials..."

  # Acquire AAD token for AKS (Azure Kubernetes Service AAD Server app)
  local aks_token
  aks_token="$(az account get-access-token \
    --resource 6dae42f8-4368-4678-94ff-3960e28e3630 \
    --query accessToken -o tsv 2>/dev/null)" || {
    warn "Failed to acquire AKS AAD token. K8s resources on AKS will fail."
    return 1
  }

  local tmpfile
  tmpfile="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '$tmpfile'" RETURN
  echo "{}" > "$tmpfile"

  # For each AKS cluster, find it via az aks list (handles ref: resource_group_name)
  local cluster_name
  while IFS= read -r cluster_name; do
    [[ -n "$cluster_name" ]] || continue
    info "Getting API server for AKS cluster '$cluster_name'..."

    # Use az aks list to find the cluster without needing the resource group
    local fqdn jmespath
    jmespath="[?name=='${cluster_name}'].privateFqdn | [0]"
    fqdn="$(az aks list --query "$jmespath" -o tsv 2>/dev/null)" || true

    # Fallback to public FQDN if no private FQDN
    if [[ -z "$fqdn" || "$fqdn" == "None" || "$fqdn" == "null" ]]; then
      jmespath="[?name=='${cluster_name}'].fqdn | [0]"
      fqdn="$(az aks list --query "$jmespath" -o tsv 2>/dev/null)" || true
    fi

    if [[ -n "$fqdn" && "$fqdn" != "None" && "$fqdn" != "null" ]]; then
      # Verify DNS resolution — private clusters require VPN/DNS connectivity
      if ! host "$fqdn" >/dev/null 2>&1; then
        die "Cannot resolve '$fqdn'. Is your VPN connected? Private AKS clusters require DNS resolution via the Azure VNet."
      fi
      local endpoint="https://${fqdn}:443"
      python3 -c "
import json, sys
creds = json.load(open(sys.argv[1]))
creds[sys.argv[2]] = {'endpoint': sys.argv[3], 'token': sys.argv[4]}
json.dump(creds, open(sys.argv[1], 'w'))
" "$tmpfile" "$cluster_name" "$endpoint" "$aks_token"
      ok "AKS credentials: $cluster_name → $fqdn"
    else
      warn "Could not resolve FQDN for AKS cluster '$cluster_name'. Skipping."
    fi
  done < <(python3 -c "
import json, sys
for name in json.loads(sys.stdin.read()):
    print(name)
" <<< "$cluster_names")

  local creds_json
  creds_json="$(cat "$tmpfile")"
  rm -f "$tmpfile"

  if [[ "$creds_json" != "{}" ]]; then
    export TF_VAR_k8s_aks_cluster_credentials="$creds_json"
    ok "AKS cluster credentials set for $(python3 -c "import json,sys; print(', '.join(json.loads(sys.stdin.read()).keys()))" <<< "$creds_json")"
    return 0
  fi

  warn "No AKS credentials extracted."
  return 1
}

# ── Rewrite backend.tf ──────────────────────────────────────────────────────
write_backend_tf() {
  local backend_type="$1"
  cat > "$BACKEND_TF" << EOF
# ── Terraform Backend ─────────────────────────────────────────────────────────
# AUTO-GENERATED by tf.sh — do not edit manually.
# Source: terraform_backend.type from the active YAML config.
#
# SAFETY: terraform_backend is read-only metadata. Preconditions in
# backend_safety.tf prevent managing backend resources from non-bootstrap configs.

terraform {
  backend "$backend_type" {}
}
EOF
}

# ── Run terraform init ──────────────────────────────────────────────────────
do_init() {
  local backend_json="$1"
  local backend_type
  backend_type="$(json_field "$backend_json" type)"

  info "Backend type: $backend_type"

  case "$backend_type" in
    local)
      local state_path
      state_path="$(json_field "$backend_json" path ".tfstate/terraform.tfstate")"
      # Ensure directory exists — state lives relative to REPO_ROOT, not .build/
      mkdir -p "$(dirname "$REPO_ROOT/$state_path")"
      local abs_state_path="$REPO_ROOT/$state_path"
      write_backend_tf "local"
      info "Running terraform init (local backend)..."
      terraform -chdir="$TF_ROOT" init -reconfigure \
        -backend-config="path=$abs_state_path"
      ;;
    azurerm)
      local rg sa container key use_azuread
      rg="$(json_field "$backend_json" resource_group_name)"
      sa="$(json_field "$backend_json" storage_account_name)"
      container="$(json_field "$backend_json" container_name tfstate)"
      key="$(json_field "$backend_json" key)"
      use_azuread="$(json_field "$backend_json" use_azuread_auth true)"
      write_backend_tf "azurerm"
      info "Running terraform init (azurerm backend)..."
      terraform -chdir="$TF_ROOT" init -reconfigure \
        -backend-config="resource_group_name=$rg" \
        -backend-config="storage_account_name=$sa" \
        -backend-config="container_name=$container" \
        -backend-config="key=$key" \
        -backend-config="use_azuread_auth=$use_azuread"
      ;;
    *)
      die "Unsupported backend type: $backend_type"
      ;;
  esac

  ok "Init complete"
}

# ── Build -var flags ─────────────────────────────────────────────────────────
build_var_flags() {
  local config_file="$1" backend_json="$2"
  local -a flags=()

  # Always pass config_file
  flags+=(-var "config_file=$config_file")

  # Build remote_state_backend and remote_state_keys from terraform_backend
  local backend_type
  backend_type="$(json_field "$backend_json" type)"

  if [[ "$backend_type" == "azurerm" ]]; then
    local remote_keys
    remote_keys="$(json_remote_states "$backend_json")"

    if [[ -n "$remote_keys" ]]; then
      local rg sa container use_azuread
      rg="$(json_field "$backend_json" resource_group_name)"
      sa="$(json_field "$backend_json" storage_account_name)"
      container="$(json_field "$backend_json" container_name tfstate)"
      use_azuread="$(json_field "$backend_json" use_azuread_auth true)"

      local backend_var
      backend_var=$(python3 -c "
import json
print(json.dumps({
  'resource_group_name': '$rg',
  'storage_account_name': '$sa',
  'container_name': '$container',
  'use_azuread_auth': $( [[ "$use_azuread" == "true" ]] && echo "True" || echo "False" )
}, separators=(',', ':')))
")
      flags+=(-var "remote_state_backend=$backend_var")
      flags+=(-var "remote_state_keys=$remote_keys")
      info "Remote states: $remote_keys" >&2
    fi
  fi

  echo "${flags[@]}"
}

# ── Upload bootstrap state to Azure Storage ─────────────────────────────────
upload_bootstrap_state() {
  local backend_json="$1"

  local upload_to
  upload_to="$(python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
ut = data.get('upload_to')
if ut:
    print(json.dumps(ut))
" <<< "$backend_json")"

  if [[ -z "$upload_to" ]]; then
    warn "No upload_to in terraform_backend — skipping state upload."
    warn "Other configs won't be able to reference bootstrap via remote_states."
    return 0
  fi

  local rg sa container key state_path
  rg="$(json_field "$upload_to" resource_group_name)"
  sa="$(json_field "$upload_to" storage_account_name)"
  container="$(json_field "$upload_to" container_name tfstate)"
  key="$(json_field "$upload_to" key bootstrap.tfstate)"
  state_path="$(json_field "$backend_json" path)"

  local full_state_path="$REPO_ROOT/$state_path"
  if [[ ! -f "$full_state_path" ]]; then
    warn "State file not found at $full_state_path — skipping upload."
    return 0
  fi

  info "Ensuring blob container '$container' exists..."
  local attempt
  for attempt in $(seq 1 5); do
    if az storage container create \
      --name "$container" \
      --account-name "$sa" \
      --auth-mode login \
      --output none 2>/dev/null; then
      break
    fi
    if [[ $attempt -lt 5 ]]; then
      warn "Container create failed (RBAC propagation). Retrying in 15s... ($attempt/5)"
      sleep 15
    fi
  done

  info "Uploading $state_path → $sa/$container/$key ..."
  local attempt max_attempts=5
  for attempt in $(seq 1 $max_attempts); do
    if az storage blob upload \
      --account-name "$sa" \
      --container-name "$container" \
      --name "$key" \
      --file "$full_state_path" \
      --overwrite \
      --auth-mode login \
      --output none 2>/dev/null; then
      break
    fi
    if [[ $attempt -lt $max_attempts ]]; then
      warn "Upload failed (RBAC propagation may take a moment). Retrying in 15s... ($attempt/$max_attempts)"
      sleep 15
    else
      die "Upload failed after $max_attempts attempts. Assign 'Storage Blob Data Contributor' manually and re-run."
    fi
  done

  ok "State uploaded to $sa/$container/$key"

  # Backup local state
  cp "$full_state_path" "${full_state_path}.bak"
  ok "Local backup: ${state_path}.bak"
}

# ── Variable metadata ────────────────────────────────────────────────────────
# Single source of truth for which TF_VAR_* each provider need requires.
# Output lines: category|var_name|description
#   auto     = tf.sh acquires automatically
#   optional = tf.sh acquires when available (non-fatal if missing)
#   manual   = user must set before running
_var_metadata() {
  local needs="$1" config_file="$2"
  if [[ "$needs" == *arm* ]]; then
    echo "auto|TF_VAR_azure_access_token|ARM bearer token"
    echo "auto|TF_VAR_subscription_id|Azure subscription ID"
    echo "auto|TF_VAR_caller_object_id|Caller object ID"
    echo "optional|TF_VAR_azure_refresh_token|MSAL refresh token (auto-renewal)"
    echo "optional|TF_VAR_azure_token_url|OAuth2 token endpoint"
  fi
  if [[ "$needs" == *graph* ]]; then
    echo "auto|TF_VAR_graph_access_token|Graph bearer token"
    echo "optional|TF_VAR_graph_refresh_token|MSAL refresh token (auto-renewal)"
    echo "optional|TF_VAR_graph_token_url|OAuth2 token endpoint"
  fi
  if [[ "$needs" == *k8s* ]]; then
    echo "auto|TF_VAR_docker_available|Docker running check"
    echo "auto|TF_VAR_k8s_cluster_credentials|Kind cluster credentials"
    echo "auto|TF_VAR_k8s_aks_cluster_credentials|AKS cluster credentials"
  fi
  if [[ "$needs" == *github* ]]; then
    echo "manual|TF_VAR_github_token|GitHub PAT or App token"
  fi
  # Cross-tenant externals require manually-provided tokens
  if [[ -n "$config_file" ]]; then
    local cross
    cross="$(python3 -c "
import yaml, sys
with open(sys.argv[1]) as f:
    cfg = yaml.safe_load(f)
for cat in cfg.get('externals', {}).values():
    if isinstance(cat, dict):
        for e in cat.values():
            if isinstance(e, dict) and '_tenant' in e:
                print('yes'); sys.exit(0)
print('no')
" "$config_file")"
    if [[ "$cross" == "yes" ]]; then
      echo "manual|TF_VAR_arm_tenant_tokens|Cross-tenant ARM bearer tokens"
    fi
  fi
}

# ── Mask sensitive values for display ────────────────────────────────────────
_mask_value() {
  local var_name="$1" value="$2"
  if [[ -z "$value" ]]; then
    echo "(not set)"
    return
  fi
  case "$var_name" in
    *_access_token|*_refresh_token|*_token|*_tokens|*_credentials)
      if [[ ${#value} -gt 16 ]]; then
        echo "${value:0:8}...${value: -4} (${#value} chars)"
      else
        echo "***masked*** (${#value} chars)"
      fi
      ;;
    *)
      echo "$value"
      ;;
  esac
}

# ── Display a group of var metadata lines ────────────────────────────────────
# Reads lines from stdin: category|var_name|description
_display_var_lines() {
  local resolve="$1"
  while IFS='|' read -r _ var desc; do
    if [[ "$resolve" == "true" ]]; then
      printf "  %-40s = %s\n" "$var" "$(_mask_value "$var" "${!var:-}")"
    else
      printf "  %-40s %s\n" "$var" "($desc)"
    fi
  done
}

# ── Vars: list variables needed for a config ─────────────────────────────────
do_vars() {
  local config_file="$1" resolve="${2:-false}"
  local config_rel="${config_file#$REPO_ROOT/}"

  local backend_json
  backend_json="$(parse_backend "$config_file")"

  local needs
  needs="$(detect_token_needs "$config_file")"

  # In resolve mode, actually acquire tokens so we can show values
  if [[ "$resolve" == "true" ]]; then
    acquire_tokens "$needs" "$config_file"
    local ci_mode="${TF_CI_MODE:-false}"
    if [[ "$needs" == *k8s* && "$ci_mode" != "true" ]]; then
      extract_k8s_credentials "$config_file" || true
      extract_aks_credentials "$config_file" || true
    fi
    echo ""
  fi

  echo -e "${BLUE}Variables for:${NC} $config_rel"
  echo ""

  # ── -var flags ──
  echo -e "${GREEN}-var flags (passed automatically):${NC}"
  echo "  -var config_file=$config_rel"
  if [[ "$backend_json" != "null" ]]; then
    local backend_type
    backend_type="$(json_field "$backend_json" type)"
    if [[ "$backend_type" == "azurerm" ]]; then
      local remote_keys
      remote_keys="$(json_remote_states "$backend_json")"
      if [[ -n "$remote_keys" ]]; then
        echo "  -var remote_state_backend={...}  (from terraform_backend)"
        echo "  -var remote_state_keys=$remote_keys"
      fi
    fi
  fi
  echo ""

  # ── TF_VAR_* env vars grouped by category ──
  local metadata
  metadata="$(_var_metadata "$needs" "$config_file")"

  if [[ -z "$metadata" ]]; then
    echo -e "${GREEN}No TF_VAR_* environment variables needed.${NC}"
    echo ""
  else
    local lines

    lines="$(echo "$metadata" | grep "^auto|" || true)"
    if [[ -n "$lines" ]]; then
      echo -e "${GREEN}Auto-acquired by tf.sh:${NC}"
      echo "$lines" | _display_var_lines "$resolve"
      echo ""
    fi

    lines="$(echo "$metadata" | grep "^optional|" || true)"
    if [[ -n "$lines" ]]; then
      echo -e "${BLUE}Optional (acquired when available):${NC}"
      echo "$lines" | _display_var_lines "$resolve"
      echo ""
    fi

    lines="$(echo "$metadata" | grep "^manual|" || true)"
    if [[ -n "$lines" ]]; then
      echo -e "${YELLOW}Must be set manually:${NC}"
      echo "$lines" | _display_var_lines "$resolve"
      echo ""
    fi
  fi

  # ── Resource maps from config ──
  echo -e "${BLUE}Resource maps in config (YAML → TF variable):${NC}"
  python3 -c "
import yaml, sys
with open(sys.argv[1]) as f:
    cfg = yaml.safe_load(f)
for key in sorted(cfg):
    if key != 'terraform_backend':
        print(f'  {key}')
" "$config_file"
  echo ""
}

# ── Status: show all terraform_backend sections ─────────────────────────────
do_status() {
  info "Scanning configurations for terraform_backend sections..."
  echo ""
  printf "%-40s %-8s %-30s %s\n" "CONFIG" "TYPE" "KEY" "REMOTE STATES"
  printf "%-40s %-8s %-30s %s\n" "------" "----" "---" "-------------"

  for f in "$REPO_ROOT"/configurations/*.yaml "$REPO_ROOT"/configurations/*/config.yaml; do
    [[ -f "$f" ]] || continue
    local rel="${f#$REPO_ROOT/}"
    python3 -c "
import yaml, sys
with open('$f') as fh:
    cfg = yaml.safe_load(fh)
tb = cfg.get('terraform_backend')
if not tb:
    sys.exit(0)
btype = tb.get('type', '?')
key = tb.get('key', tb.get('path', '?'))
rs = tb.get('remote_states', {})
rs_names = ', '.join(rs.keys()) if rs else '—'
print(f'$rel|{btype}|{key}|{rs_names}')
" | while IFS='|' read -r rel btype key rs; do
      printf "%-40s %-8s %-30s %s\n" "$rel" "$btype" "$key" "$rs"
    done
  done
  echo ""
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
  local action="${1:-}"
  local config_file="${2:-}"

  if [[ "$action" == "status" ]]; then
    do_status
    exit 0
  fi

  if [[ "$action" == "vars" ]]; then
    local resolve=false cf=""
    shift # past "vars"
    for arg in "$@"; do
      case "$arg" in
        --resolve) resolve=true ;;
        *) [[ -z "$cf" ]] && cf="$arg" ;;
      esac
    done
    [[ -n "$cf" ]] || die "Usage: ./tf.sh vars [--resolve] <config_file>"
    if [[ ! "$cf" = /* ]]; then
      cf="$REPO_ROOT/$cf"
    fi
    [[ -f "$cf" ]] || die "Config file not found: $cf"
    do_vars "$cf" "$resolve"
    exit 0
  fi

  if [[ -z "$action" || -z "$config_file" ]]; then
    cat << 'USAGE'
Usage: ./tf.sh <action> <config_file>

Actions:
  init           Configure backend + terraform init
  plan           init + terraform plan
  apply          init + terraform apply (bootstrap: + state upload)
  destroy        init + terraform destroy
  output         init + terraform output
  force-unlock   Break the state lock (azurerm: blob lease break)
  import         Import an existing resource into state
  vars           List variables needed for a config (--resolve to show values)
  status         Show all terraform_backend sections

Examples:
  ./tf.sh plan configurations/00-bootstrap/config.yaml
  ./tf.sh apply configurations/01-launchpad/config.yaml
  ./tf.sh vars configurations/01-launchpad/config.yaml
  ./tf.sh vars --resolve configurations/01-launchpad/config.yaml
  ./tf.sh status
USAGE
    exit 1
  fi

  # Resolve config path relative to repo root
  if [[ ! "$config_file" = /* ]]; then
    config_file="$REPO_ROOT/$config_file"
  fi
  [[ -f "$config_file" ]] || die "Config file not found: $config_file"

  # Relative path for -var config_file
  local config_rel="${config_file#$REPO_ROOT/}"

  # Parse terraform_backend
  local backend_json
  backend_json="$(parse_backend "$config_file")"
  [[ "$backend_json" != "null" ]] || die "No terraform_backend section in $config_rel"

  # Validate backend configuration
  validate_backend "$backend_json" "$config_rel" || die "Backend validation failed"

  local backend_type
  backend_type="$(json_field "$backend_json" type)"
  info "Config:  $config_rel"
  info "Backend: $backend_type"

  # Detect and acquire tokens
  local needs
  needs="$(detect_token_needs "$config_file")"
  acquire_tokens "$needs" "$config_file"

  # Extract K8s credentials from existing clusters (skip in CI mode)
  local ci_mode="${TF_CI_MODE:-false}"
  if [[ "$needs" == *k8s* && "$ci_mode" != "true" ]]; then
    extract_k8s_credentials "$config_file" || true
    extract_aks_credentials "$config_file" || true
  fi

  # Shift past action and config for extra args
  shift 2
  local -a extra_args=("$@")

  # Build flat Terraform root from galaxy/ source
  info "Assembling .build/ from galaxy/ ..."
  "$REPO_ROOT/scripts/build-galaxy.sh"

  # Init
  do_init "$backend_json"

  # Build var flags
  local var_flags
  var_flags="$(build_var_flags "$config_rel" "$backend_json")"

  case "$action" in
    init)
      ok "Ready. Run: ./tf.sh plan $config_rel"
      ;;
    plan)
      info "Running terraform plan..."
      # shellcheck disable=SC2086
      terraform -chdir="$TF_ROOT" plan $var_flags "${extra_args[@]+"${extra_args[@]}"}"
      ;;
    apply)
      info "Running terraform apply..."
      # shellcheck disable=SC2086
      terraform -chdir="$TF_ROOT" apply $var_flags "${extra_args[@]+"${extra_args[@]}"}"

      # Bootstrap special: upload state after successful apply
      if [[ "$backend_type" == "local" ]]; then
        echo ""
        info "── Post-apply: uploading state to Azure Storage ──"
        upload_bootstrap_state "$backend_json"
      fi
      ;;
    destroy)
      # K8s-aware destroy: if kind clusters are gone (containers deleted),
      # remove their K8s resources and tokens from state so destroy doesn't
      # fail trying to connect to non-existent clusters.
      if [[ "$needs" == *k8s* ]]; then
        local existing_clusters
        existing_clusters="$(kind get clusters 2>/dev/null)" || true

        if [[ -z "$existing_clusters" ]]; then
          warn "No kind clusters found — removing K8s and token resources from state..."
          _remove_k8s_from_state
        fi
      fi

      info "Running terraform destroy..."
      # shellcheck disable=SC2086
      terraform -chdir="$TF_ROOT" destroy $var_flags "${extra_args[@]+"${extra_args[@]}"}"
      ;;
    output)
      info "Running terraform output..."
      terraform -chdir="$TF_ROOT" output "${extra_args[@]+"${extra_args[@]}"}"
      ;;
    force-unlock)
      if [[ "$backend_type" == "azurerm" ]]; then
        local sa container key
        sa="$(json_field "$backend_json" storage_account_name)"
        container="$(json_field "$backend_json" container_name tfstate)"
        key="$(json_field "$backend_json" key)"
        info "Breaking blob lease on $sa/$container/$key ..."
        az storage blob lease break \
          --blob-name "$key" \
          --container-name "$container" \
          --account-name "$sa" \
          --auth-mode login
        ok "State lock released."
      elif [[ "$backend_type" == "local" ]]; then
        info "Local backend — no remote lock to break."
      else
        die "force-unlock not implemented for backend type: $backend_type"
      fi
      ;;
    import)
      info "Running terraform import..."
      # shellcheck disable=SC2086
      terraform -chdir="$TF_ROOT" import $var_flags "${extra_args[@]+"${extra_args[@]}"}"
      ;;
    *)
      die "Unknown action: $action (expected: init|plan|apply|destroy|output|force-unlock|import|vars|status)"
      ;;
  esac
}

main "$@"
