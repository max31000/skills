#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERWRITE_SKILLS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --overwrite-skills)
      OVERWRITE_SKILLS=true
      shift
      ;;
    -h|--help)
      printf 'Usage: bash bootstrap.sh [--overwrite-skills]\n'
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [[ "$OVERWRITE_SKILLS" == "true" ]]; then
  exec bash "$ROOT_DIR/scripts/bootstrap.sh" --overwrite-skills
fi

exec bash "$ROOT_DIR/scripts/bootstrap.sh"
