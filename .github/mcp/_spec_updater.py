"""Shared helper: keep a *-specs submodule at upstream HEAD on server startup.

Each spec MCP server calls ``ensure_latest(submodule_root, log=_log)`` once,
right after it resolves its ``*_SPECS_ROOT`` path. The helper fast-forwards
the submodule to ``origin/HEAD`` if enough time has passed since the last
check, does nothing if the network is unreachable, and never raises.

Environment:
    MCP_SPECS_AUTOUPDATE             set to "0" to disable (default "1")
    MCP_SPECS_UPDATE_INTERVAL_HOURS  throttle interval (default 24)
"""

from __future__ import annotations

import os
import subprocess
import time
from pathlib import Path
from typing import Callable

_DEFAULT_INTERVAL_HOURS = 24
_FETCH_TIMEOUT_SECONDS = 30
_GIT_TIMEOUT_SECONDS = 10


def _noop(_msg: str) -> None:
    pass


def _resolve_git_dir(submodule_root: Path) -> Path | None:
    """Return the real git dir for a submodule checkout, or None."""
    dot_git = submodule_root / ".git"
    if dot_git.is_dir():
        return dot_git
    if dot_git.is_file():
        try:
            line = dot_git.read_text().strip()
        except OSError:
            return None
        if line.startswith("gitdir:"):
            target = line.split(":", 1)[1].strip()
            resolved = (submodule_root / target).resolve()
            if resolved.exists():
                return resolved
    return None


def ensure_initialized(submodule_root: Path, log: Callable[[str], None] = _noop) -> None:
    """Run ``git submodule update --init`` for *submodule_root* if not yet checked out.

    Finds the superproject root by walking up to the directory that contains
    ``.gitmodules``, then runs ``git submodule update --init --recommend-shallow
    --depth 1 <relative-path>``.  Silent on failure — the server will surface
    the missing content as a tool error when a caller actually needs it.
    """
    name = submodule_root.name or str(submodule_root)

    if _resolve_git_dir(submodule_root) is not None:
        return  # already initialized

    # Walk up to find the superproject root (directory containing .gitmodules)
    superproject = submodule_root.resolve()
    for _ in range(10):
        superproject = superproject.parent
        if (superproject / ".gitmodules").exists():
            break
    else:
        log(f"init: could not find superproject root for [{name}]")
        return

    try:
        rel = submodule_root.resolve().relative_to(superproject)
    except ValueError:
        log(f"init: submodule not under superproject [{name}]")
        return

    log(f"init: submodule not initialized — running git submodule update --init [{rel}]")
    try:
        result = subprocess.run(
            [
                "git", "-C", str(superproject),
                "submodule", "update", "--init", "--recommend-shallow", "--depth", "1",
                str(rel),
            ],
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode == 0:
            log(f"init: submodule initialized [{name}]")
        else:
            err = result.stderr.strip().splitlines()[-1] if result.stderr.strip() else "unknown"
            log(f"init: submodule init failed ({err[:160]}) [{name}]")
    except subprocess.TimeoutExpired:
        log(f"init: submodule init timed out [{name}]")
    except Exception as exc:
        log(f"init: unexpected error {exc!r} [{name}]")


def ensure_latest(submodule_root: Path, log: Callable[[str], None] = _noop) -> None:
    """Fast-forward ``submodule_root`` to origin/HEAD if stale.

    Silent on network failure; skips if the working tree is dirty; throttled
    by a stamp file in the submodule's git dir.
    """
    name = submodule_root.name or str(submodule_root)

    if os.environ.get("MCP_SPECS_AUTOUPDATE", "1") == "0":
        log(f"autoupdate disabled via MCP_SPECS_AUTOUPDATE=0 [{name}]")
        return

    git_dir = _resolve_git_dir(submodule_root)
    if git_dir is None:
        log(f"autoupdate skipped: not a git checkout [{name}]")
        return

    try:
        interval_hours = int(
            os.environ.get("MCP_SPECS_UPDATE_INTERVAL_HOURS", _DEFAULT_INTERVAL_HOURS)
        )
    except ValueError:
        interval_hours = _DEFAULT_INTERVAL_HOURS

    stamp = git_dir / "mcp-last-update-check"
    try:
        if stamp.exists() and (time.time() - stamp.stat().st_mtime) < interval_hours * 3600:
            log(f"autoupdate: recent check, skipping [{name}]")
            return
    except OSError:
        pass

    try:
        dirty = subprocess.run(
            ["git", "-C", str(submodule_root), "status", "--porcelain"],
            capture_output=True,
            text=True,
            timeout=_GIT_TIMEOUT_SECONDS,
        )
        if dirty.returncode != 0:
            log(f"autoupdate: git status failed, skipping [{name}]")
            return
        if dirty.stdout.strip():
            log(f"autoupdate: working tree dirty, skipping [{name}]")
            return

        fetch = subprocess.run(
            ["git", "-C", str(submodule_root), "fetch", "--depth=1", "--quiet", "origin", "HEAD"],
            capture_output=True,
            text=True,
            timeout=_FETCH_TIMEOUT_SECONDS,
        )
        if fetch.returncode != 0:
            err = fetch.stderr.strip().splitlines()[-1] if fetch.stderr.strip() else "unknown"
            log(f"autoupdate: fetch failed ({err[:160]}) [{name}]")
            return

        before = subprocess.run(
            ["git", "-C", str(submodule_root), "rev-parse", "HEAD"],
            capture_output=True, text=True, timeout=_GIT_TIMEOUT_SECONDS,
        ).stdout.strip()
        after = subprocess.run(
            ["git", "-C", str(submodule_root), "rev-parse", "FETCH_HEAD"],
            capture_output=True, text=True, timeout=_GIT_TIMEOUT_SECONDS,
        ).stdout.strip()

        if before and after and before == after:
            log(f"autoupdate: already at upstream HEAD {after[:12]} [{name}]")
        else:
            reset = subprocess.run(
                ["git", "-C", str(submodule_root), "reset", "--hard", "--quiet", "FETCH_HEAD"],
                capture_output=True,
                text=True,
                timeout=_GIT_TIMEOUT_SECONDS,
            )
            if reset.returncode != 0:
                log(f"autoupdate: reset failed, skipping [{name}]")
                return
            log(f"autoupdate: {before[:12]} -> {after[:12]} [{name}]")

        try:
            stamp.touch()
        except OSError:
            pass
    except subprocess.TimeoutExpired:
        log(f"autoupdate: timeout, skipping [{name}]")
    except Exception as exc:  # pragma: no cover - defensive
        log(f"autoupdate: unexpected error {exc!r} [{name}]")
