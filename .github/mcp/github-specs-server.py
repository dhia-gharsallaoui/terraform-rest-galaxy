#!/usr/bin/env python3
"""
GitHub REST API Specs MCP Server

Parses the local github/rest-api-description repository to discover
API variants (api.github.com, ghec, ghes-*), dated versions, search
paths, and inspect operation details from the OpenAPI v3 specs.

The repo has this layout:
  descriptions/
    api.github.com/           (GitHub.com public)
      api.github.com.json                     (latest, bundled)
      api.github.com.2022-11-28.json          (dated version)
      api.github.com.2026-03-10.json          (dated version)
      dereferenced/
        api.github.com.deref.json             (latest, dereferenced)
        api.github.com.2022-11-28.deref.json
    ghec/                     (GitHub Enterprise Cloud)
    ghes-3.20/                (GitHub Enterprise Server)
    ...

Because the files are large (~12MB each), specs are parsed lazily on
first use and cached in memory.

Environment:
  GITHUB_SPECS_ROOT  — path to the rest-api-description repo root
                       (default: specs/rest-api-description, relative to repo root)
"""

import sys
import json
import os
import datetime
import re
from pathlib import Path

# ── Debug log ─────────────────────────────────────────────────────────────────
_LOG_PATH = os.environ.get("GITHUB_SPECS_LOG", "/tmp/github-specs-mcp.log")


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
        "GITHUB_SPECS_ROOT",
        str(_REPO_ROOT / "specs/rest-api-description"),
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


# ── Lazy spec loading & caching ──────────────────────────────────────────────

_spec_cache: dict[str, dict] = {}        # cache_key → parsed spec
_path_index: dict[str, dict] = {}        # cache_key → {path_str: {method: op_dict}}
_tag_index: dict[str, list] = {}         # cache_key → sorted list of tags


def _spec_key(variant: str, api_date: str) -> str:
    """Build a cache key from variant + api_date."""
    return f"{variant}:{api_date}" if api_date else f"{variant}:latest"


def _resolve_spec_file(variant: str, api_date: str) -> Path:
    """Resolve the JSON spec file path for a variant and optional api_date."""
    desc_dir = REPO_ROOT / "descriptions" / variant
    if not desc_dir.is_dir():
        raise ValueError(f"Variant '{variant}' not found at {desc_dir}")
    if api_date:
        fname = f"{variant}.{api_date}.json"
    else:
        fname = f"{variant}.json"
    spec_file = desc_dir / fname
    if not spec_file.is_file():
        raise ValueError(f"Spec file not found: {spec_file}")
    return spec_file


def _load_spec(variant: str, api_date: str = "") -> dict:
    """Load and cache the OpenAPI spec for a variant and optional api_date."""
    key = _spec_key(variant, api_date)
    if key in _spec_cache:
        return _spec_cache[key]
    spec_file = _resolve_spec_file(variant, api_date)
    _log(f"Loading {spec_file} ...")
    with open(spec_file, "r", encoding="utf-8") as f:
        spec = json.load(f)
    _spec_cache[key] = spec
    _log(f"Loaded {key}: {len(spec.get('paths', {}))} paths")
    return spec


def _get_path_index(variant: str, api_date: str = "") -> dict:
    """Build or return the path index: {path_str: {method: operation}}."""
    key = _spec_key(variant, api_date)
    if key in _path_index:
        return _path_index[key]
    spec = _load_spec(variant, api_date)
    index = {}
    for path_str, methods in spec.get("paths", {}).items():
        ops = {}
        for method, op in methods.items():
            if isinstance(op, dict) and method in ("get", "post", "put", "patch", "delete"):
                ops[method] = op
        if ops:
            index[path_str] = ops
    _path_index[key] = index
    return index


def _get_tags(variant: str, api_date: str = "") -> list[str]:
    """Return sorted list of API tags (categories)."""
    key = _spec_key(variant, api_date)
    if key in _tag_index:
        return _tag_index[key]
    spec = _load_spec(variant, api_date)
    tags = sorted(t["name"] for t in spec.get("tags", []) if isinstance(t, dict) and "name" in t)
    _tag_index[key] = tags
    return tags


# ── Schema helpers ────────────────────────────────────────────────────────────


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
    """Inline $refs up to 2 levels deep."""
    if depth > 2:
        return schema
    if "$ref" in schema:
        return _inline_schema(_resolve_ref(schema["$ref"], spec), spec, depth + 1)
    result = dict(schema)
    if "properties" in result:
        result["properties"] = {
            k: _inline_schema(v, spec, depth + 1)
            for k, v in result["properties"].items()
        }
    if "allOf" in result:
        merged = {}
        for sub in result["allOf"]:
            inlined = _inline_schema(sub, spec, depth + 1)
            merged.update(inlined.get("properties", {}))
        result.setdefault("properties", {})
        result["properties"] = {**merged, **result["properties"]}
        del result["allOf"]
    if "oneOf" in result:
        result["oneOf"] = [_inline_schema(s, spec, depth + 1) for s in result["oneOf"]]
    if "anyOf" in result:
        result["anyOf"] = [_inline_schema(s, spec, depth + 1) for s in result["anyOf"]]
    return result


# ── Tool implementations ─────────────────────────────────────────────────────


def tool_list_variants(args: dict) -> list[dict]:
    """List available GitHub API variants from the descriptions/ directory."""
    desc_dir = REPO_ROOT / "descriptions"
    if not desc_dir.is_dir():
        raise ValueError(f"descriptions/ directory not found at {desc_dir}")
    variants = []
    for d in sorted(desc_dir.iterdir()):
        if not d.is_dir():
            continue
        # Find available dated versions
        json_files = sorted(f.name for f in d.iterdir() if f.suffix == ".json" and not f.name.startswith("."))
        api_dates = []
        for jf in json_files:
            # Parse: <variant>.<date>.json or <variant>.json
            stem = jf[:-5]  # remove .json
            prefix = d.name + "."
            if stem == d.name:
                api_dates.append("latest")
            elif stem.startswith(prefix):
                api_dates.append(stem[len(prefix):])
        variant_type = "github.com"
        if d.name == "ghec":
            variant_type = "enterprise-cloud"
        elif d.name.startswith("ghes-"):
            variant_type = "enterprise-server"
        variants.append({
            "variant": d.name,
            "type": variant_type,
            "api_dates": api_dates,
        })
    return variants


def tool_list_tags(args: dict) -> list[str]:
    """List API tags (categories like 'repos', 'issues', 'actions') for a variant."""
    variant = args.get("variant", "api.github.com")
    api_date = args.get("api_date", "")
    return _get_tags(variant, api_date)


def tool_find_path(args: dict) -> list[dict]:
    """
    Search for API paths matching a keyword.
    Matches against path segments, operationId, summary, and tags.
    """
    keyword = args["keyword"].lower()
    variant = args.get("variant", "api.github.com")
    api_date = args.get("api_date", "")
    method_filter = args.get("method", "").lower()
    tag_filter = args.get("tag", "").lower()
    limit = min(args.get("limit", 30), 100)

    index = _get_path_index(variant, api_date)
    results = []

    for path_str, methods in index.items():
        path_lower = path_str.lower()
        for method, op in methods.items():
            if method_filter and method != method_filter:
                continue
            op_tags = [t.lower() for t in op.get("tags", [])]
            if tag_filter and tag_filter not in op_tags:
                continue
            op_id = (op.get("operationId") or "").lower()
            op_summary = (op.get("summary") or "").lower()
            op_desc = (op.get("description") or "").lower()
            if (keyword not in path_lower and keyword not in op_id
                    and keyword not in op_summary and keyword not in op_desc
                    and not any(keyword in t for t in op_tags)):
                continue
            x_github = op.get("x-github", {})
            results.append({
                "path": path_str,
                "method": method.upper(),
                "operation_id": op.get("operationId"),
                "summary": (op.get("summary") or op.get("description") or "")[:200],
                "tags": op.get("tags", []),
                "category": x_github.get("category"),
                "subcategory": x_github.get("subcategory"),
            })
            if len(results) >= limit:
                break
        if len(results) >= limit:
            break

    return results


def tool_get_operation(args: dict) -> dict:
    """
    Get detailed information about a specific API operation including
    parameters, request body schema (inlined), and response schemas.
    """
    variant = args.get("variant", "api.github.com")
    api_date = args.get("api_date", "")
    path = args["path"]
    method = args["method"].lower()

    spec = _load_spec(variant, api_date)
    path_entry = spec.get("paths", {}).get(path)
    if not path_entry:
        raise ValueError(f"Path not found: {path}")
    op = path_entry.get(method)
    if not op or not isinstance(op, dict):
        raise ValueError(f"Method {method.upper()} not found for path: {path}")

    x_github = op.get("x-github", {})
    result = {
        "path": path,
        "method": method.upper(),
        "operation_id": op.get("operationId"),
        "summary": op.get("summary"),
        "description": (op.get("description") or "")[:1000],
        "tags": op.get("tags", []),
        "category": x_github.get("category"),
        "subcategory": x_github.get("subcategory"),
        "github_cloud_only": x_github.get("githubCloudOnly", False),
        "enabled_for_github_apps": x_github.get("enabledForGitHubApps", False),
        "parameters": [],
    }

    # Parameters
    for param in op.get("parameters", []):
        if isinstance(param, dict):
            if "$ref" in param:
                param = _resolve_ref(param["$ref"], spec)
            schema = param.get("schema", {})
            result["parameters"].append({
                "name": param.get("name"),
                "in": param.get("in"),
                "required": param.get("required", False),
                "description": (param.get("description") or "")[:200],
                "type": schema.get("type") if isinstance(schema, dict) else None,
            })

    # Request body (OpenAPI 3.x)
    req_body = op.get("requestBody")
    if req_body:
        if "$ref" in req_body:
            req_body = _resolve_ref(req_body["$ref"], spec)
        for content_type, media in req_body.get("content", {}).items():
            if "json" in content_type:
                schema = media.get("schema", {})
                inlined = _inline_schema(schema, spec)
                result["request_body"] = {
                    "content_type": content_type,
                    "required": req_body.get("required", False),
                    "schema": inlined,
                }
                props = inlined.get("properties", {})
                result["writable_properties"] = [
                    k for k, v in props.items()
                    if not v.get("readOnly")
                ]
                result["readonly_properties"] = [
                    k for k, v in props.items()
                    if v.get("readOnly")
                ]
                break

    # Response summary (success response schema)
    responses = op.get("responses", {})
    for code in ("200", "201", "202", "204"):
        resp = responses.get(code)
        if resp and isinstance(resp, dict):
            for ct, media in resp.get("content", {}).items():
                if "json" in ct:
                    schema = media.get("schema", {})
                    inlined = _inline_schema(schema, spec)
                    result["response_schema"] = inlined
                    break
            break

    return result


def tool_get_resource_summary(args: dict) -> dict:
    """
    Get a summary of all operations for a tag (category) or path prefix.
    Lists all paths and methods matching the filter.
    """
    variant = args.get("variant", "api.github.com")
    api_date = args.get("api_date", "")
    tag = args.get("tag", "").lower()
    prefix = args.get("prefix", "")

    if not tag and not prefix:
        raise ValueError("Either 'tag' or 'prefix' must be provided")

    index = _get_path_index(variant, api_date)
    operations = []

    for path_str, methods in index.items():
        for method, op in methods.items():
            match = False
            if tag:
                op_tags = [t.lower() for t in op.get("tags", [])]
                match = tag in op_tags
            if prefix and not match:
                match = path_str == prefix or path_str.startswith(prefix + "/") or path_str.startswith(prefix + "{")
            if match:
                x_github = op.get("x-github", {})
                operations.append({
                    "path": path_str,
                    "method": method.upper(),
                    "operation_id": op.get("operationId"),
                    "summary": (op.get("summary") or "")[:200],
                    "category": x_github.get("category"),
                    "subcategory": x_github.get("subcategory"),
                })

    if not operations:
        raise ValueError(f"No operations found for tag='{tag}' prefix='{prefix}'")

    return {
        "variant": variant,
        "api_date": api_date or "latest",
        "filter": {"tag": tag, "prefix": prefix},
        "operation_count": len(operations),
        "operations": operations,
    }


# ── Tool registry ─────────────────────────────────────────────────────────────

TOOLS = [
    {
        "name": "list_variants",
        "description": (
            "List available GitHub API variants and their dated API versions. "
            "Variants include: api.github.com (public GitHub), ghec (Enterprise Cloud), "
            "ghes-X.Y (Enterprise Server). Each variant may have multiple dated API versions "
            "(e.g. 2022-11-28, 2026-03-10)."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
    {
        "name": "list_tags",
        "description": (
            "List API tags (categories) for a GitHub API variant. "
            "Tags correspond to API categories like 'repos', 'issues', 'actions', "
            "'pulls', 'orgs', 'users', etc. Use this to discover what resource categories exist."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "variant": {
                    "type": "string",
                    "description": "API variant: 'api.github.com' (default), 'ghec', or 'ghes-X.Y'",
                    "default": "api.github.com",
                },
                "api_date": {
                    "type": "string",
                    "description": "Dated API version (e.g. '2022-11-28'). Empty = latest.",
                    "default": "",
                },
            },
        },
    },
    {
        "name": "find_path",
        "description": (
            "Search for GitHub API paths matching a keyword. Matches against path segments, "
            "operationId, summary, description, and tags. Returns paths with methods, summaries, "
            "and GitHub-specific metadata (category, subcategory). "
            "Use this to find specific API operations like creating repos, managing issues, etc."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["keyword"],
            "properties": {
                "keyword": {
                    "type": "string",
                    "description": "Case-insensitive keyword to search (e.g. 'repository', 'issue', 'workflow', 'pull')",
                },
                "variant": {
                    "type": "string",
                    "description": "API variant: 'api.github.com' (default), 'ghec', or 'ghes-X.Y'",
                    "default": "api.github.com",
                },
                "api_date": {
                    "type": "string",
                    "description": "Dated API version (e.g. '2022-11-28'). Empty = latest.",
                    "default": "",
                },
                "method": {
                    "type": "string",
                    "description": "Filter by HTTP method (e.g. 'post', 'get'). Empty = all methods.",
                    "default": "",
                },
                "tag": {
                    "type": "string",
                    "description": "Filter by tag/category (e.g. 'repos', 'issues'). Empty = all tags.",
                    "default": "",
                },
                "limit": {
                    "type": "integer",
                    "description": "Max results to return (default 30, max 100)",
                    "default": 30,
                },
            },
        },
    },
    {
        "name": "get_operation",
        "description": (
            "Get detailed information about a specific GitHub API operation including "
            "parameters, request body schema (inlined), writable/readonly properties, "
            "and response schema. Use after find_path to inspect a specific endpoint."
        ),
        "inputSchema": {
            "type": "object",
            "required": ["path", "method"],
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Full API path (e.g. '/repos/{owner}/{repo}', '/orgs/{org}/repos')",
                },
                "method": {
                    "type": "string",
                    "description": "HTTP method (e.g. 'get', 'post', 'patch', 'delete')",
                },
                "variant": {
                    "type": "string",
                    "description": "API variant: 'api.github.com' (default), 'ghec', or 'ghes-X.Y'",
                    "default": "api.github.com",
                },
                "api_date": {
                    "type": "string",
                    "description": "Dated API version. Empty = latest.",
                    "default": "",
                },
            },
        },
    },
    {
        "name": "get_resource_summary",
        "description": (
            "Get a summary of ALL operations for a tag (category) or path prefix. "
            "Lists every matching path and method. Use to understand the full surface area "
            "of a resource category (e.g. all 'repos' operations, all '/orgs' endpoints)."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "tag": {
                    "type": "string",
                    "description": "Filter by tag/category (e.g. 'repos', 'issues', 'actions')",
                    "default": "",
                },
                "prefix": {
                    "type": "string",
                    "description": "Filter by path prefix (e.g. '/repos/{owner}/{repo}/actions')",
                    "default": "",
                },
                "variant": {
                    "type": "string",
                    "description": "API variant: 'api.github.com' (default), 'ghec', or 'ghes-X.Y'",
                    "default": "api.github.com",
                },
                "api_date": {
                    "type": "string",
                    "description": "Dated API version. Empty = latest.",
                    "default": "",
                },
            },
        },
    },
]

TOOL_FNS = {
    "list_variants": tool_list_variants,
    "list_tags": tool_list_tags,
    "find_path": tool_find_path,
    "get_operation": tool_get_operation,
    "get_resource_summary": tool_get_resource_summary,
}

# ── Request handler ───────────────────────────────────────────────────────────


def _handle(msg: dict) -> None:
    method = msg.get("method", "")
    req_id = msg.get("id")
    params = msg.get("params") or {}

    if method == "initialize":
        _ok(req_id, {
            "protocolVersion": "2024-11-05",
            "serverInfo": {"name": "github-specs", "version": "1.0.0"},
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
            _ok(req_id, {
                "content": [{"type": "text", "text": f"Error: {exc}"}],
                "isError": True,
            })

    elif req_id is not None:
        _err(req_id, -32601, f"Method not found: {method}")


def main() -> None:
    _log(f"github-specs-server started  REPO_ROOT={REPO_ROOT}")
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
            sys.stderr.write(f"github-specs-server error: {exc}\n")
            sys.stderr.flush()


if __name__ == "__main__":
    main()
