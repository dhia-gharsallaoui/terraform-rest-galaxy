#!/usr/bin/env python3
"""
Kubernetes API Specs MCP Server

Parses the local kubernetes/kubernetes repository to discover
API groups, resource types, and inspect operation details from the
OpenAPI v3 specs — pinned to a specific Kubernetes release version.

The repo has this layout (at any given git tag / branch):
  api/openapi-spec/
    swagger.json                              (consolidated Swagger 2.0)
    v3/
      api__v1_openapi.json                    (core v1 resources)
      apis__apps__v1_openapi.json             (apps/v1 resources)
      apis__batch__v1_openapi.json            (batch/v1 resources)
      apis__networking.k8s.io__v1_openapi.json
      ...

The server supports **version pinning**: every tool accepts a `kube_version`
parameter (e.g. "1.30", "1.34.3", "1.28.0").  When the requested version
differs from the currently checked-out tag, the server runs
`git checkout v<kube_version>` to switch and reloads specs.

Environment:
  K8S_SPECS_ROOT  — path to the kubernetes/kubernetes repo root
                    (default: specs/kubernetes, relative to repo root)
"""

import sys
import json
import os
import subprocess
import datetime
import re
from pathlib import Path

# ── Debug log ─────────────────────────────────────────────────────────────────
_LOG_PATH = os.environ.get("K8S_SPECS_LOG", "/tmp/kubernetes-specs-mcp.log")


def _log(msg: str) -> None:
    try:
        ts = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
        with open(_LOG_PATH, "a") as f:
            f.write(f"{ts} {msg}\n")
    except Exception:
        pass


_REPO_ROOT = Path(__file__).resolve().parent.parent.parent
REPO_ROOT = Path(
    os.environ.get(
        "K8S_SPECS_ROOT",
        str(_REPO_ROOT / "specs/kubernetes"),
    )
)

# ── Keep the backing submodule fresh on startup ───────────────────────────────
sys.path.insert(0, str(Path(__file__).parent))
try:
    from _spec_updater import ensure_initialized, ensure_latest

    ensure_initialized(REPO_ROOT, log=_log)
    ensure_latest(REPO_ROOT, log=_log)
except Exception as _exc:  # pragma: no cover - defensive
    _log(f"spec auto-update skipped: {_exc!r}")

OPENAPI_V3_DIR = "api/openapi-spec/v3"
SWAGGER_PATH = "api/openapi-spec/swagger.json"

# ── MCP JSON-RPC transport ────────────────────────────────────────────────────


def _read_message() -> dict | None:
    while True:
        try:
            line = sys.stdin.buffer.readline()
        except Exception as exc:
            _log(f"stdin read error: {exc}")
            return None
        if not line:
            _log("EOF on stdin")
            return None
        line = line.strip()
        if not line:
            continue
        try:
            return json.loads(line)
        except json.JSONDecodeError as exc:
            _log(f"JSON error: {exc}  raw={line[:120]!r}")
            continue


def _send(data: dict) -> None:
    frame = json.dumps(data, ensure_ascii=False).encode("utf-8") + b"\n"
    os.write(1, frame)


def _ok(req_id, result) -> None:
    _send({"jsonrpc": "2.0", "id": req_id, "result": result})


def _err(req_id, code: int, message: str) -> None:
    _send({"jsonrpc": "2.0", "id": req_id, "error": {"code": code, "message": message}})


# ── Version management ────────────────────────────────────────────────────────

_current_version: str = ""  # the currently checked-out version tag


def _detect_current_version() -> str:
    """Detect which version tag is currently checked out."""
    try:
        result = subprocess.run(
            ["git", "describe", "--tags", "--exact-match", "HEAD"],
            capture_output=True, text=True, cwd=REPO_ROOT,
            timeout=10,
        )
        if result.returncode == 0:
            tag = result.stdout.strip()
            if tag.startswith("v"):
                return tag[1:]  # strip leading 'v'
            return tag
    except Exception as exc:
        _log(f"_detect_current_version error: {exc}")
    return "unknown"


def _resolve_version_tag(kube_version: str) -> str:
    """Resolve a user-supplied version string to a git tag.

    Accepts: "1.34", "1.34.3", "v1.34.3", "1.30.0"
    Returns the best matching tag string (e.g. "v1.34.3").
    """
    ver = kube_version.strip().lstrip("v")
    if not ver:
        return ""

    # Validate format
    if not re.match(r"^\d+\.\d+(\.\d+)?$", ver):
        raise ValueError(
            f"Invalid version format '{kube_version}'. "
            "Expected: '1.34', '1.34.3', or 'v1.34.3'"
        )

    # If patch version given, try exact tag
    if re.match(r"^\d+\.\d+\.\d+$", ver):
        return f"v{ver}"

    # Minor-only: find the latest patch for that minor
    result = subprocess.run(
        ["git", "tag", "--list", f"v{ver}.*"],
        capture_output=True, text=True, cwd=REPO_ROOT,
        timeout=10,
    )
    if result.returncode != 0:
        raise ValueError(f"Failed to list tags for v{ver}.*")

    tags = [
        t.strip() for t in result.stdout.strip().split("\n")
        if t.strip() and re.match(rf"^v{re.escape(ver)}\.\d+$", t.strip())
    ]
    if not tags:
        raise ValueError(f"No tags found matching v{ver}.*")

    # Sort by patch number and pick highest
    def patch_num(tag: str) -> int:
        parts = tag.split(".")
        return int(parts[-1]) if parts[-1].isdigit() else 0

    tags.sort(key=patch_num)
    return tags[-1]


def _checkout_version(kube_version: str) -> str:
    """Switch the git repo to the requested version if needed.
    Returns the full version string (without 'v' prefix)."""
    global _current_version

    if not kube_version:
        # Use whatever is currently checked out
        if not _current_version:
            _current_version = _detect_current_version()
        return _current_version

    tag = _resolve_version_tag(kube_version)
    tag_ver = tag.lstrip("v")

    if tag_ver == _current_version:
        return _current_version

    _log(f"Switching from {_current_version} to {tag} ...")
    result = subprocess.run(
        ["git", "checkout", tag, "--quiet"],
        capture_output=True, text=True, cwd=REPO_ROOT,
        timeout=30,
    )
    if result.returncode != 0:
        raise ValueError(
            f"git checkout {tag} failed: {result.stderr.strip()}"
        )

    # Clear all caches since we changed versions
    _spec_cache.clear()
    _group_index.clear()
    _resource_index.clear()
    _schema_index.clear()

    _current_version = tag_ver
    _log(f"Now on version {_current_version}")
    return _current_version


# ── Lazy spec loading & caching ──────────────────────────────────────────────

_spec_cache: dict[str, dict] = {}         # file_key → parsed spec
_group_index: dict[str, list] = {}        # "groups" → [{group, versions, file}]
_resource_index: dict[str, dict] = {}     # "resources" → {kind: {info}}
_schema_index: dict[str, dict] = {}       # schema_name → schema_dict


def _list_spec_files() -> list[Path]:
    """List all OpenAPI v3 spec files in the current checkout."""
    v3_dir = REPO_ROOT / OPENAPI_V3_DIR
    if not v3_dir.is_dir():
        raise ValueError(f"OpenAPI v3 directory not found: {v3_dir}")
    return sorted(v3_dir.glob("*.json"))


def _parse_spec_filename(filename: str) -> dict | None:
    """Parse an OpenAPI spec filename to extract group and version.

    Examples:
      api__v1_openapi.json          → group="", version="v1"
      apis__apps__v1_openapi.json   → group="apps", version="v1"
      apis__networking.k8s.io__v1_openapi.json → group="networking.k8s.io", version="v1"
      apis__apps_openapi.json       → group="apps", version="" (discovery doc)
    """
    stem = filename.replace("_openapi.json", "")

    if stem == "api__v1":
        return {"group": "", "version": "v1", "is_core": True}
    if stem == "api":
        return None  # discovery doc, skip

    if not stem.startswith("apis__"):
        return None

    rest = stem[6:]  # strip "apis__"
    parts = rest.split("__")

    if len(parts) == 1:
        # Discovery doc like apis__apps_openapi.json → skip
        return None
    elif len(parts) == 2:
        return {"group": parts[0], "version": parts[1], "is_core": False}
    else:
        return None


def _load_spec(spec_file: Path) -> dict:
    """Load and cache a single OpenAPI spec file."""
    key = spec_file.name
    if key in _spec_cache:
        return _spec_cache[key]
    _log(f"Loading {spec_file.name} ...")
    with open(spec_file, "r", encoding="utf-8") as f:
        spec = json.load(f)
    _spec_cache[key] = spec
    _log(f"Loaded {key}: {len(spec.get('paths', {}))} paths, "
         f"{len(spec.get('components', {}).get('schemas', {}))} schemas")
    return spec


def _build_group_index() -> list[dict]:
    """Build the index of API groups and their versions."""
    if "groups" in _group_index:
        return _group_index["groups"]

    groups_map: dict[str, dict] = {}  # group_name → {versions, resources_by_version}

    for spec_file in _list_spec_files():
        info = _parse_spec_filename(spec_file.name)
        if info is None or not info["version"]:
            continue

        group_name = info["group"] or "core"
        if group_name not in groups_map:
            groups_map[group_name] = {
                "group": info["group"],
                "display_name": group_name,
                "is_core": info.get("is_core", False),
                "versions": [],
                "spec_files": {},
            }
        groups_map[group_name]["versions"].append(info["version"])
        groups_map[group_name]["spec_files"][info["version"]] = spec_file.name

    result = sorted(groups_map.values(), key=lambda g: g["display_name"])
    for g in result:
        g["versions"] = sorted(g["versions"])
    _group_index["groups"] = result
    return result


def _build_resource_index() -> dict[str, dict]:
    """Build the index of all resource types across all API groups."""
    if _resource_index:
        return _resource_index

    for spec_file in _list_spec_files():
        file_info = _parse_spec_filename(spec_file.name)
        if file_info is None or not file_info["version"]:
            continue

        spec = _load_spec(spec_file)
        schemas = spec.get("components", {}).get("schemas", {})

        # Find top-level resource types via x-kubernetes-group-version-kind
        for schema_name, schema in schemas.items():
            gvks = schema.get("x-kubernetes-group-version-kind", [])
            for gvk in gvks:
                kind = gvk.get("kind", "")
                if not kind or kind.endswith("List"):
                    continue  # skip list types

                # Determine if namespaced by checking paths
                group = gvk.get("group", "")
                version = gvk.get("version", "")
                plural = _kind_to_plural(kind)

                # Build path prefix
                if not group:
                    path_prefix = f"/api/{version}"
                else:
                    path_prefix = f"/apis/{group}/{version}"

                namespaced = f"{path_prefix}/namespaces/{{namespace}}/{plural}/{{name}}" in spec.get("paths", {})
                cluster_path = f"{path_prefix}/{plural}/{{name}}" in spec.get("paths", {})

                # Determine scope
                if namespaced:
                    scope = "Namespaced"
                elif cluster_path:
                    scope = "Cluster"
                else:
                    scope = "Unknown"

                resource_key = f"{group}/{version}/{kind}"
                _resource_index[resource_key] = {
                    "kind": kind,
                    "group": group,
                    "version": version,
                    "plural": plural,
                    "scope": scope,
                    "schema_name": schema_name,
                    "spec_file": spec_file.name,
                    "api_version": f"{group}/{version}" if group else version,
                }

    return _resource_index


# ── Kubernetes-specific helpers ───────────────────────────────────────────────

# Standard kind → plural mappings (irregular plurals)
_IRREGULAR_PLURALS = {
    "Endpoints": "endpoints",
    "Ingress": "ingresses",
    "IngressClass": "ingressclasses",
    "NetworkPolicy": "networkpolicies",
    "StorageClass": "storageclasses",
    "RuntimeClass": "runtimeclasses",
    "PriorityClass": "priorityclasses",
    "IngressClassParams": "ingressclassparams",
    "EndpointSlice": "endpointslices",
}


def _kind_to_plural(kind: str) -> str:
    """Convert a Kubernetes Kind to its plural resource name."""
    if kind in _IRREGULAR_PLURALS:
        return _IRREGULAR_PLURALS[kind]
    lower = kind.lower()
    if lower.endswith("ss") or lower.endswith("s"):
        return lower + "es" if lower.endswith("ss") else lower
    if lower.endswith("y") and lower[-2] not in "aeiou":
        return lower[:-1] + "ies"
    return lower + "s"


def _resolve_ref(ref: str, spec: dict) -> dict:
    """Resolve a local JSON $ref (e.g. '#/components/schemas/Foo')."""
    if not ref.startswith("#/"):
        return {}
    node = spec
    for part in ref[2:].split("/"):
        if isinstance(node, dict):
            node = node.get(part, {})
        else:
            return {}
    return node if isinstance(node, dict) else {}


def _inline_schema(schema: dict, spec: dict, depth: int = 0) -> dict:
    """Inline $refs up to a configurable depth."""
    if depth > 3:
        if "$ref" in schema:
            return {"$ref": schema["$ref"], "_truncated": True}
        return schema
    if "$ref" in schema:
        resolved = _resolve_ref(schema["$ref"], spec)
        resolved = dict(resolved)
        resolved["_from_ref"] = schema["$ref"]
        return _inline_schema(resolved, spec, depth + 1)
    result = dict(schema)
    if "properties" in result:
        result["properties"] = {
            k: _inline_schema(v, spec, depth + 1)
            for k, v in result["properties"].items()
        }
    if "items" in result and isinstance(result["items"], dict):
        result["items"] = _inline_schema(result["items"], spec, depth + 1)
    if "allOf" in result:
        merged_props = {}
        merged_desc = result.get("description", "")
        for sub in result["allOf"]:
            inlined = _inline_schema(sub, spec, depth + 1)
            merged_props.update(inlined.get("properties", {}))
            if not merged_desc and inlined.get("description"):
                merged_desc = inlined["description"]
        result.setdefault("properties", {})
        result["properties"] = {**merged_props, **result["properties"]}
        if merged_desc:
            result["description"] = merged_desc
        del result["allOf"]
    if "oneOf" in result:
        result["oneOf"] = [_inline_schema(s, spec, depth + 1) for s in result["oneOf"]]
    if "anyOf" in result:
        result["anyOf"] = [_inline_schema(s, spec, depth + 1) for s in result["anyOf"]]
    return result


def _extract_properties(schema: dict, section: str, spec: dict) -> dict:
    """Extract properties from spec or status section of a resource schema."""
    props = schema.get("properties", {})
    section_schema = props.get(section)
    if not section_schema:
        return {}
    if "$ref" in section_schema:
        section_schema = _resolve_ref(section_schema["$ref"], spec)
    elif "allOf" in section_schema:
        # Merge allOf
        merged = {}
        for sub in section_schema["allOf"]:
            if "$ref" in sub:
                resolved = _resolve_ref(sub["$ref"], spec)
                merged.update(resolved.get("properties", {}))
            else:
                merged.update(sub.get("properties", {}))
        return merged
    return section_schema.get("properties", {})


# ── Tool implementations ─────────────────────────────────────────────────────


def tool_list_versions(args: dict) -> dict:
    """List available Kubernetes versions (git tags) in the local repo."""
    result = subprocess.run(
        ["git", "tag", "--list", "v1.*"],
        capture_output=True, text=True, cwd=REPO_ROOT,
        timeout=15,
    )
    if result.returncode != 0:
        raise ValueError(f"git tag list failed: {result.stderr.strip()}")

    all_tags = [
        t.strip() for t in result.stdout.strip().split("\n")
        if t.strip() and re.match(r"^v\d+\.\d+\.\d+$", t.strip())
    ]

    # Group by minor version
    minors: dict[str, list[str]] = {}
    for tag in all_tags:
        parts = tag[1:].split(".")
        minor_key = f"{parts[0]}.{parts[1]}"
        minors.setdefault(minor_key, []).append(tag)

    # Sort and pick latest patch per minor
    sorted_minors = sorted(minors.keys(), key=lambda m: tuple(int(x) for x in m.split(".")))

    versions = []
    for minor in sorted_minors:
        patches = sorted(minors[minor], key=lambda t: int(t.split(".")[-1]))
        versions.append({
            "minor": minor,
            "latest_patch": patches[-1],
            "patch_count": len(patches),
            "all_patches": patches,
        })

    return {
        "current_version": _current_version or _detect_current_version(),
        "minor_versions": len(versions),
        "versions": versions[-10:],  # last 10 minor versions
    }


def tool_list_api_groups(args: dict) -> list[dict]:
    """List all API groups and their versions for the given Kubernetes version."""
    kube_version = args.get("kube_version", "")
    actual_ver = _checkout_version(kube_version)

    groups = _build_group_index()
    result = []
    for g in groups:
        result.append({
            "group": g["group"] or "(core)",
            "display_name": g["display_name"],
            "is_core": g["is_core"],
            "versions": g["versions"],
        })

    return {
        "kube_version": actual_ver,
        "group_count": len(result),
        "groups": result,
    }


def tool_find_resource(args: dict) -> dict:
    """Search for Kubernetes resource types matching a keyword."""
    keyword = args["keyword"].lower()
    kube_version = args.get("kube_version", "")
    group_filter = args.get("group", "").lower()
    scope_filter = args.get("scope", "").lower()
    limit = min(args.get("limit", 30), 100)

    actual_ver = _checkout_version(kube_version)
    index = _build_resource_index()

    results = []
    for key, info in sorted(index.items()):
        # Apply filters
        if group_filter:
            g = info["group"].lower() if info["group"] else "core"
            if group_filter not in g:
                continue
        if scope_filter and info["scope"].lower() != scope_filter:
            continue

        # Keyword match against kind, group, plural, api_version
        searchable = f"{info['kind']} {info['group']} {info['plural']} {info['api_version']}".lower()
        if keyword not in searchable:
            continue

        results.append({
            "kind": info["kind"],
            "api_version": info["api_version"],
            "group": info["group"] or "(core)",
            "version": info["version"],
            "plural": info["plural"],
            "scope": info["scope"],
            "schema_name": info["schema_name"],
        })
        if len(results) >= limit:
            break

    return {
        "kube_version": actual_ver,
        "match_count": len(results),
        "resources": results,
    }


def tool_get_resource_schema(args: dict) -> dict:
    """Get the full schema for a Kubernetes resource type.

    Returns the spec (writable) and status (read-only) properties,
    metadata fields, and the full path patterns for CRUD operations.
    """
    kind = args["kind"]
    kube_version = args.get("kube_version", "")
    api_version = args.get("api_version", "")
    inline_depth = min(args.get("inline_depth", 2), 4)

    actual_ver = _checkout_version(kube_version)
    index = _build_resource_index()

    # Find the resource
    candidates = [
        info for key, info in index.items()
        if info["kind"].lower() == kind.lower()
    ]
    if api_version:
        api_version_lower = api_version.lower()
        filtered = [c for c in candidates if c["api_version"].lower() == api_version_lower]
        if filtered:
            candidates = filtered

    if not candidates:
        raise ValueError(
            f"Resource kind '{kind}' not found in Kubernetes {actual_ver}. "
            f"Use find_resource to search for available kinds."
        )

    # Prefer stable versions: v1 > v2 > v1beta1 > v1alpha1
    def version_priority(info: dict) -> tuple:
        v = info["version"]
        if "alpha" in v:
            return (2, v)
        if "beta" in v:
            return (1, v)
        return (0, v)

    candidates.sort(key=version_priority)
    resource = candidates[0]

    # Load the spec file and find the schema
    spec_file = REPO_ROOT / OPENAPI_V3_DIR / resource["spec_file"]
    spec = _load_spec(spec_file)
    schema = spec.get("components", {}).get("schemas", {}).get(resource["schema_name"], {})

    if not schema:
        raise ValueError(f"Schema '{resource['schema_name']}' not found in {resource['spec_file']}")

    # Extract spec and status properties
    spec_props = _extract_properties(schema, "spec", spec)
    status_props = _extract_properties(schema, "status", spec)

    # Inline spec properties to requested depth
    inlined_spec_props = {}
    for prop_name, prop_schema in spec_props.items():
        inlined_spec_props[prop_name] = _inline_schema(prop_schema, spec, depth=4 - inline_depth)

    # Build CRUD path patterns
    group = resource["group"]
    version = resource["version"]
    plural = resource["plural"]

    if not group:
        prefix = f"/api/{version}"
    else:
        prefix = f"/apis/{group}/{version}"

    paths = {}
    if resource["scope"] == "Namespaced":
        paths = {
            "create": f"{prefix}/namespaces/{{namespace}}/{plural}",
            "read": f"{prefix}/namespaces/{{namespace}}/{plural}/{{name}}",
            "update": f"{prefix}/namespaces/{{namespace}}/{plural}/{{name}}",
            "delete": f"{prefix}/namespaces/{{namespace}}/{plural}/{{name}}",
            "list_namespaced": f"{prefix}/namespaces/{{namespace}}/{plural}",
            "list_all": f"{prefix}/{plural}",
        }
    else:
        paths = {
            "create": f"{prefix}/{plural}",
            "read": f"{prefix}/{plural}/{{name}}",
            "update": f"{prefix}/{plural}/{{name}}",
            "delete": f"{prefix}/{plural}/{{name}}",
            "list": f"{prefix}/{plural}",
        }

    # Check for subresources (status, scale, etc.)
    spec_paths = spec.get("paths", {})
    subresources = []
    for p in spec_paths:
        if resource["scope"] == "Namespaced":
            sr_prefix = f"{prefix}/namespaces/{{namespace}}/{plural}/{{name}}/"
        else:
            sr_prefix = f"{prefix}/{plural}/{{name}}/"
        if p.startswith(sr_prefix):
            sub_name = p[len(sr_prefix):]
            if "/" not in sub_name:
                subresources.append(sub_name)

    # Build writable/readonly property lists
    writable_properties = sorted(inlined_spec_props.keys())
    readonly_properties = sorted(status_props.keys())

    return {
        "kube_version": actual_ver,
        "kind": resource["kind"],
        "api_version": resource["api_version"],
        "group": resource["group"] or "(core)",
        "version": resource["version"],
        "plural": resource["plural"],
        "scope": resource["scope"],
        "schema_name": resource["schema_name"],
        "paths": paths,
        "subresources": subresources,
        "writable_properties": writable_properties,
        "readonly_properties": readonly_properties,
        "spec_schema": inlined_spec_props,
        "status_schema_properties": sorted(status_props.keys()),
        "description": schema.get("description", ""),
    }


def tool_get_operation(args: dict) -> dict:
    """Get detailed information about a specific API operation (path + method)."""
    path = args["path"]
    method = args["method"].lower()
    kube_version = args.get("kube_version", "")

    actual_ver = _checkout_version(kube_version)

    # Find which spec file contains this path
    target_spec = None
    target_file = None
    for spec_file in _list_spec_files():
        file_info = _parse_spec_filename(spec_file.name)
        if file_info is None or not file_info["version"]:
            continue
        spec = _load_spec(spec_file)
        if path in spec.get("paths", {}):
            target_spec = spec
            target_file = spec_file.name
            break

    if target_spec is None:
        raise ValueError(f"Path '{path}' not found in any OpenAPI spec for Kubernetes {actual_ver}")

    path_entry = target_spec["paths"][path]
    op = path_entry.get(method)
    if not op or not isinstance(op, dict):
        available = [m for m in path_entry if m in ("get", "post", "put", "patch", "delete")]
        raise ValueError(
            f"Method {method.upper()} not found for path '{path}'. "
            f"Available methods: {', '.join(m.upper() for m in available)}"
        )

    result = {
        "kube_version": actual_ver,
        "spec_file": target_file,
        "path": path,
        "method": method.upper(),
        "operation_id": op.get("operationId"),
        "description": (op.get("description") or "")[:1000],
        "tags": op.get("tags", []),
        "parameters": [],
    }

    # Parameters (path + query + shared)
    all_params = list(op.get("parameters", []))
    # Include path-level parameters
    shared_params = path_entry.get("parameters", [])
    if isinstance(shared_params, list):
        all_params = shared_params + all_params

    for param in all_params:
        if isinstance(param, dict):
            if "$ref" in param:
                param = _resolve_ref(param["$ref"], target_spec)
            if not isinstance(param, dict):
                continue
            schema = param.get("schema", {})
            result["parameters"].append({
                "name": param.get("name"),
                "in": param.get("in"),
                "required": param.get("required", False),
                "description": (param.get("description") or "")[:200],
                "type": schema.get("type") if isinstance(schema, dict) else None,
            })

    # Request body
    req_body = op.get("requestBody")
    if req_body:
        if "$ref" in req_body:
            req_body = _resolve_ref(req_body["$ref"], target_spec)
        for content_type, media in req_body.get("content", {}).items():
            schema = media.get("schema", {})
            inlined = _inline_schema(schema, target_spec, depth=1)
            result["request_body"] = {
                "content_type": content_type,
                "required": req_body.get("required", False),
                "schema_ref": schema.get("$ref", ""),
                "schema_summary": {
                    k: v.get("description", "")[:100] if isinstance(v, dict) else str(v)
                    for k, v in inlined.get("properties", {}).items()
                },
            }
            break

    # Response summary
    responses = op.get("responses", {})
    for code in ("200", "201", "202"):
        resp = responses.get(code)
        if resp and isinstance(resp, dict):
            for ct, media in resp.get("content", {}).items():
                schema = media.get("schema", {})
                result["response"] = {
                    "status_code": code,
                    "content_type": ct,
                    "schema_ref": schema.get("$ref", ""),
                }
                break
            break

    return result


def tool_get_schema_detail(args: dict) -> dict:
    """Get the full inlined schema for a specific schema reference.

    Use this to drill into nested types referenced by get_resource_schema,
    e.g. 'io.k8s.api.core.v1.PodSpec' or 'io.k8s.api.core.v1.Container'.
    """
    schema_name = args["schema_name"]
    kube_version = args.get("kube_version", "")
    inline_depth = min(args.get("inline_depth", 2), 4)

    actual_ver = _checkout_version(kube_version)

    # Search all spec files for this schema
    target_schema = None
    target_file = None
    for spec_file in _list_spec_files():
        file_info = _parse_spec_filename(spec_file.name)
        if file_info is None or not file_info["version"]:
            continue
        spec = _load_spec(spec_file)
        schemas = spec.get("components", {}).get("schemas", {})
        if schema_name in schemas:
            target_schema = schemas[schema_name]
            target_file = spec_file.name
            break

    if target_schema is None:
        # Try partial match
        for spec_file in _list_spec_files():
            file_info = _parse_spec_filename(spec_file.name)
            if file_info is None or not file_info["version"]:
                continue
            spec = _load_spec(spec_file)
            schemas = spec.get("components", {}).get("schemas", {})
            matches = [
                name for name in schemas
                if schema_name.lower() in name.lower()
            ]
            if matches:
                # Return the closest match
                matches.sort(key=len)
                target_schema = schemas[matches[0]]
                schema_name = matches[0]
                target_file = spec_file.name
                break

    if target_schema is None:
        raise ValueError(
            f"Schema '{schema_name}' not found. Use find_resource or "
            f"get_resource_schema first to discover schema names."
        )

    spec = _load_spec(REPO_ROOT / OPENAPI_V3_DIR / target_file)
    inlined = _inline_schema(target_schema, spec, depth=4 - inline_depth)

    # Classify properties
    properties = inlined.get("properties", {})
    required = set(inlined.get("required", []))

    prop_list = []
    for name, prop in sorted(properties.items()):
        prop_info = {
            "name": name,
            "type": prop.get("type", "object"),
            "description": (prop.get("description") or "")[:300],
            "required": name in required,
        }
        if "format" in prop:
            prop_info["format"] = prop["format"]
        if "default" in prop:
            prop_info["default"] = prop["default"]
        if "enum" in prop:
            prop_info["enum"] = prop["enum"]
        if "$ref" in prop or "_from_ref" in prop:
            prop_info["ref"] = prop.get("_from_ref", prop.get("$ref", ""))
        if prop.get("type") == "array" and "items" in prop:
            items = prop["items"]
            if "$ref" in items or "_from_ref" in items:
                prop_info["items_ref"] = items.get("_from_ref", items.get("$ref", ""))
        # Nested properties summary
        if "properties" in prop:
            prop_info["nested_properties"] = sorted(prop["properties"].keys())
        prop_list.append(prop_info)

    return {
        "kube_version": actual_ver,
        "schema_name": schema_name,
        "spec_file": target_file,
        "description": inlined.get("description", ""),
        "type": inlined.get("type", "object"),
        "required": sorted(required),
        "property_count": len(prop_list),
        "properties": prop_list,
    }


# ── Tool registry ─────────────────────────────────────────────────────────────

TOOLS = [
    {
        "name": "list_versions",
        "description": (
            "List available Kubernetes versions in the local kubernetes/kubernetes "
            "repository. Shows the last 10 minor releases with their latest patch "
            "versions. Use this to discover which Kubernetes versions are available "
            "for spec inspection. The current checked-out version is also returned."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
    {
        "name": "list_api_groups",
        "description": (
            "List all API groups and their versions for a specific Kubernetes release. "
            "Returns groups like 'core' (v1), 'apps' (v1), 'batch' (v1), "
            "'networking.k8s.io' (v1), 'rbac.authorization.k8s.io' (v1), etc. "
            "Use this to discover what API groups exist in a given Kubernetes version."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "kube_version": {
                    "type": "string",
                    "description": (
                        "Kubernetes version to inspect (e.g. '1.30', '1.34.3'). "
                        "If omitted, uses the currently checked-out version. "
                        "IMPORTANT: Always pin to the target cluster's version."
                    ),
                    "default": "",
                },
            },
        },
    },
    {
        "name": "find_resource",
        "description": (
            "Search for Kubernetes resource types by keyword. Matches against "
            "kind, group, plural name, and apiVersion. Returns the kind, apiVersion, "
            "scope (Namespaced/Cluster), and plural name for matching resources. "
            "Use this as the first step to discover available resource types."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["keyword"],
            "properties": {
                "keyword": {
                    "type": "string",
                    "description": (
                        "Case-insensitive keyword to search "
                        "(e.g. 'deployment', 'service', 'ingress', 'configmap')"
                    ),
                },
                "kube_version": {
                    "type": "string",
                    "description": (
                        "Kubernetes version (e.g. '1.30', '1.34.3'). "
                        "Empty = current checkout."
                    ),
                    "default": "",
                },
                "group": {
                    "type": "string",
                    "description": "Filter by API group (e.g. 'apps', 'batch', 'networking.k8s.io')",
                    "default": "",
                },
                "scope": {
                    "type": "string",
                    "description": "Filter by scope: 'namespaced' or 'cluster'",
                    "default": "",
                },
                "limit": {
                    "type": "integer",
                    "description": "Max results (default 30, max 100)",
                    "default": 30,
                },
            },
        },
    },
    {
        "name": "get_resource_schema",
        "description": (
            "Get the full schema for a Kubernetes resource type, including: "
            "writable properties (spec), read-only properties (status), "
            "CRUD path patterns, subresources, and the inlined spec schema. "
            "This is the primary tool for understanding a resource's structure "
            "when generating Terraform modules. Always specify kube_version "
            "to pin to the target cluster version."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["kind"],
            "properties": {
                "kind": {
                    "type": "string",
                    "description": "Resource kind (e.g. 'Deployment', 'Service', 'ConfigMap')",
                },
                "kube_version": {
                    "type": "string",
                    "description": (
                        "Kubernetes version (e.g. '1.30', '1.34.3'). "
                        "CRITICAL: Pin to the target cluster's version to get "
                        "the correct schema — fields differ across versions."
                    ),
                    "default": "",
                },
                "api_version": {
                    "type": "string",
                    "description": (
                        "Specific apiVersion (e.g. 'apps/v1', 'v1'). "
                        "If omitted, the stable version is preferred."
                    ),
                    "default": "",
                },
                "inline_depth": {
                    "type": "integer",
                    "description": "How deep to inline $ref schemas (default 2, max 4)",
                    "default": 2,
                },
            },
        },
    },
    {
        "name": "get_operation",
        "description": (
            "Get detailed information about a specific Kubernetes API operation "
            "(path + method). Returns parameters, request body schema reference, "
            "and response schema. Use after find_resource or get_resource_schema "
            "to inspect a specific CRUD endpoint."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["path", "method"],
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Full API path (e.g. '/apis/apps/v1/namespaces/{namespace}/deployments')",
                },
                "method": {
                    "type": "string",
                    "description": "HTTP method (e.g. 'get', 'post', 'put', 'delete')",
                },
                "kube_version": {
                    "type": "string",
                    "description": "Kubernetes version (e.g. '1.30', '1.34.3'). Empty = current checkout.",
                    "default": "",
                },
            },
        },
    },
    {
        "name": "get_schema_detail",
        "description": (
            "Get the full inlined schema for a nested type referenced in a resource schema. "
            "Use this to drill into complex types like 'io.k8s.api.core.v1.PodSpec', "
            "'io.k8s.api.core.v1.Container', 'io.k8s.api.core.v1.Volume', etc. "
            "Supports partial name matching (e.g. 'PodSpec' will find 'io.k8s.api.core.v1.PodSpec')."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["schema_name"],
            "properties": {
                "schema_name": {
                    "type": "string",
                    "description": (
                        "Full or partial schema name "
                        "(e.g. 'io.k8s.api.core.v1.PodSpec' or 'PodSpec')"
                    ),
                },
                "kube_version": {
                    "type": "string",
                    "description": "Kubernetes version. Empty = current checkout.",
                    "default": "",
                },
                "inline_depth": {
                    "type": "integer",
                    "description": "How deep to inline nested $refs (default 2, max 4)",
                    "default": 2,
                },
            },
        },
    },
]

TOOL_FNS = {
    "list_versions": tool_list_versions,
    "list_api_groups": tool_list_api_groups,
    "find_resource": tool_find_resource,
    "get_resource_schema": tool_get_resource_schema,
    "get_operation": tool_get_operation,
    "get_schema_detail": tool_get_schema_detail,
}

# ── Request handler ───────────────────────────────────────────────────────────


def _handle(msg: dict) -> None:
    method = msg.get("method", "")
    req_id = msg.get("id")
    params = msg.get("params") or {}

    if method == "initialize":
        _ok(req_id, {
            "protocolVersion": "2024-11-05",
            "serverInfo": {"name": "kubernetes-specs", "version": "1.0.0"},
            "capabilities": {"tools": {}},
        })

    elif method in ("notifications/initialized", "initialized"):
        pass

    elif method == "tools/list":
        _ok(req_id, {"tools": TOOLS})

    elif method == "tools/call":
        name = params.get("name", "")
        arguments = params.get("arguments") or {}
        fn = TOOL_FNS.get(name)
        if fn is None:
            _err(req_id, -32601, f"Unknown tool: {name}")
            return
        try:
            result = fn(arguments)
            _ok(req_id, {
                "content": [{"type": "text", "text": json.dumps(result, indent=2, ensure_ascii=False)}]
            })
        except Exception as exc:
            _log(f"tool {name} error: {exc}")
            _ok(req_id, {
                "content": [{"type": "text", "text": f"Error: {exc}"}],
                "isError": True,
            })

    elif req_id is not None:
        _err(req_id, -32601, f"Method not found: {method}")


def main() -> None:
    global _current_version
    _current_version = _detect_current_version()
    _log(f"kubernetes-specs-server started  REPO_ROOT={REPO_ROOT}  version={_current_version}")
    while True:
        try:
            msg = _read_message()
            if msg is None:
                _log("shutting down")
                break
            method = msg.get("method", "<no method>")
            _log(f"recv method={method!r} id={msg.get('id')!r}")
            _handle(msg)
        except Exception as exc:
            _log(f"unhandled error: {exc}")
            sys.stderr.write(f"kubernetes-specs-server error: {exc}\n")
            sys.stderr.flush()


if __name__ == "__main__":
    main()
