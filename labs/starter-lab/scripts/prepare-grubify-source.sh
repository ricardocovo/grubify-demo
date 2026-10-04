#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$LAB_DIR/src/grubify"
BASE_COMMIT="6592accc6eef73e2d7c7339885386480cb49838f"
OUTPUT_DIR="${1:?Usage: prepare-grubify-source.sh <empty-output-directory>}"

if [ -d "$OUTPUT_DIR" ] && [ -n "$(ls -A "$OUTPUT_DIR")" ]; then
  echo "ERROR: The output directory must be empty: $OUTPUT_DIR" >&2
  exit 1
fi

if [ ! -f "$SOURCE_DIR/.git" ]; then
  git -C "$LAB_DIR" submodule update --init -- src/grubify >&2
fi

mkdir -p "$OUTPUT_DIR"
git -C "$SOURCE_DIR" archive "$BASE_COMMIT" | tar -x -C "$OUTPUT_DIR"
git -C "$OUTPUT_DIR" apply --check "$LAB_DIR/patches/grubify-app-fixes.patch"
git -C "$OUTPUT_DIR" apply "$LAB_DIR/patches/grubify-app-fixes.patch"
echo "Prepared patched Grubify source in $OUTPUT_DIR"
