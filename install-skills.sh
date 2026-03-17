#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERWRITE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --overwrite)
      OVERWRITE=true
      shift
      ;;
    -h|--help)
      printf 'Usage: bash install-skills.sh [--overwrite]\n'
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [[ "$OVERWRITE" == "true" ]]; then
  exec bash "$ROOT_DIR/scripts/install-skills.sh" --overwrite
fi

exec bash "$ROOT_DIR/scripts/install-skills.sh"
