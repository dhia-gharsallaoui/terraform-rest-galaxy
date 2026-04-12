#!/usr/bin/env bash
# ── build-galaxy: assemble flat Terraform root from organized galaxy/ source ──
#
# Naming convention (no config file needed):
#   galaxy/shared/<name>.tf                    →  <name>.tf
#   galaxy/<provider>/<sub>/<name>.tf          →  <provider>__<sub>__<name>.tf
#   galaxy/<provider>/<sub>/<sub2>/<name>.tf   →  <provider>__<sub>__<sub2>__<name>.tf
#
# Add new .tf files to the right galaxy/ subdirectory and they are
# automatically picked up — no mapping file to maintain.
#
# Usage:
#   scripts/build-galaxy.sh            # build .build/ from galaxy/
#   scripts/build-galaxy.sh --check    # dry-run, report what would be built
#   scripts/build-galaxy.sh --clean    # remove .build/
#   scripts/build-galaxy.sh --reverse  # sync .build/ changes back to galaxy/
#
# The .build/ directory is gitignored and ephemeral.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GALAXY_DIR="$REPO_ROOT/galaxy"
BUILD_DIR="$REPO_ROOT/.build"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

die() { echo -e "${RED}error:${NC} $*" >&2; exit 1; }

# ── Derive the flat Terraform filename from an organized path ────────────────
# galaxy/shared/main.tf                → main.tf
# galaxy/azure/networking/vnets.tf     → azure__networking__vnets.tf
# galaxy/entraid/_meta/layers.tf       → entraid___meta__layers.tf
# galaxy/k8s/kind_clusters.tf          → k8s__kind_clusters.tf
flat_name() {
  local rel="$1"  # path relative to galaxy/, e.g. azure/networking/vnets.tf
  local provider

  provider="${rel%%/*}"       # azure, entraid, github, k8s, shared

  if [[ "$provider" == "shared" ]]; then
    echo "${rel##*/}"         # just the filename
  else
    # Replace all / with __ to encode the full path
    echo "${rel//\//__}"
  fi
}

# ── Reverse: derive galaxy/ path from a flat filename ───────────────────────
# azure__networking__vnets.tf     → azure/networking/vnets.tf
# entraid___meta__layers.tf       → entraid/_meta/layers.tf
# main.tf (no __)                 → shared/main.tf
galaxy_path() {
  local flat="$1"  # e.g. azure__networking__vnets.tf
  if [[ "$flat" != *__* ]]; then
    echo "shared/$flat"
  else
    # Replace __ with / to reconstruct the organized path
    echo "${flat//__//}"
  fi
}

# ── Clean mode ───────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--clean" ]]; then
  rm -rf "$BUILD_DIR"
  echo -e "${GREEN}cleaned${NC} .build/"
  exit 0
fi

# ── Reverse mode: sync .build/ changes back to galaxy/ ──────────────────────
if [[ "${1:-}" == "--reverse" ]]; then
  [ -d "$BUILD_DIR" ] || die ".build/ directory not found — run a forward build first"
  echo -e "${YELLOW}reverse sync${NC} .build/ → galaxy/ ..."

  count=0
  updated=0
  for flat_file in "$BUILD_DIR"/*.tf; do
    [ -f "$flat_file" ] || continue
    flat="$(basename "$flat_file")"
    rel="$(galaxy_path "$flat")"
    target="$GALAXY_DIR/$rel"

    # Skip files that don't differ
    if [ -f "$target" ] && diff -q "$flat_file" "$target" > /dev/null 2>&1; then
      count=$((count + 1))
      continue
    fi

    # Create parent directory if this is a new file
    mkdir -p "$(dirname "$target")"
    cp "$flat_file" "$target"
    if [ -f "$target" ]; then
      echo -e "  ${GREEN}updated${NC} $rel"
    else
      echo -e "  ${GREEN}new${NC}     $rel"
    fi
    updated=$((updated + 1))
    count=$((count + 1))
  done

  echo -e "${GREEN}done${NC}: $count files scanned, $updated updated in galaxy/"
  exit 0
fi

# ── Discover all .tf files ───────────────────────────────────────────────────
[ -d "$GALAXY_DIR" ] || die "galaxy/ directory not found"

mapfile -t source_files < <(find "$GALAXY_DIR" -name '*.tf' -type f | sort)
(( ${#source_files[@]} > 0 )) || die "no .tf files found in galaxy/"

# ── Check for collisions ────────────────────────────────────────────────────
declare -A seen
collisions=0
for src in "${source_files[@]}"; do
  rel="${src#$GALAXY_DIR/}"
  flat="$(flat_name "$rel")"
  if [[ -n "${seen[$flat]:-}" ]]; then
    echo -e "${RED}collision:${NC} $flat ← $rel AND ${seen[$flat]}"
    collisions=$((collisions + 1))
  fi
  seen[$flat]="$rel"
done
(( collisions == 0 )) || die "$collisions filename collisions detected — rename source files to resolve"

# ── Check mode ───────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--check" ]]; then
  echo -e "${GREEN}check passed${NC}: ${#source_files[@]} files, 0 collisions"
  for flat in $(printf '%s\n' "${!seen[@]}" | sort); do
    echo "  $flat ← ${seen[$flat]}"
  done
  exit 0
fi

# ── Build mode ───────────────────────────────────────────────────────────────
echo -e "${YELLOW}building${NC} .build/ from galaxy/ ..."

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

count=0
for src in "${source_files[@]}"; do
  rel="${src#$GALAXY_DIR/}"
  flat="$(flat_name "$rel")"
  cp "$src" "$BUILD_DIR/$flat"
  count=$((count + 1))
done

# Link supporting directories and files
ln -s "$REPO_ROOT/modules"        "$BUILD_DIR/modules"
ln -s "$REPO_ROOT/configurations" "$BUILD_DIR/configurations"
ln -s "$REPO_ROOT/tests"          "$BUILD_DIR/tests"
ln -s "$REPO_ROOT/examples"       "$BUILD_DIR/examples"
cp    "$REPO_ROOT/externals_schema.yaml" "$BUILD_DIR/externals_schema.yaml"

echo -e "${GREEN}done${NC}: $count .tf files → .build/"
