#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$ROOT_DIR/manifest/plugins/plugins.manifest.json"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'Skipping plugin install: python3 not found.\n'
  exit 0
fi

python3 "$SCRIPT_DIR/plugin_backend.py" --manifest "$MANIFEST" --home "$HOME"
