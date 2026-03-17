#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$ROOT_DIR/.bootstrap-logs/$(date +%Y%m%dT%H%M%S)"
OVERWRITE_SKILLS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --overwrite-skills)
      OVERWRITE_SKILLS=true
      shift
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

mkdir -p "$LOG_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'FAIL: required dependency `python3` is unavailable.\n'
  printf 'Bootstrap cannot continue because preflight and config rendering depend on it.\n'
  exit 1
fi

PREFLIGHT_FILE="$LOG_DIR/preflight.json"
python3 "$SCRIPT_DIR/bootstrap_deps.py" preflight --root "$ROOT_DIR" --log-dir "$LOG_DIR" >"$PREFLIGHT_FILE"

python3 - "$PREFLIGHT_FILE" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
for line in payload.get("lines", []):
    print(line)
for warning in payload.get("warnings", []):
    print(f"warn {warning['name']}")
PY

run_step() {
  local label="$1"
  shift
  printf '\n==> %s\n' "$label"
  "$@"
}

BOOTSTRAP_LOG_DIR="$LOG_DIR" BOOTSTRAP_NONINTERACTIVE=1 run_step "Installing packages" bash "$SCRIPT_DIR/install-packages.sh"
BOOTSTRAP_LOG_DIR="$LOG_DIR" BOOTSTRAP_NONINTERACTIVE=1 run_step "Installing tool versions" bash "$SCRIPT_DIR/install-tools.sh"
run_step "Rendering configs" python3 "$SCRIPT_DIR/render-configs.py" --root "$ROOT_DIR"
if [[ "$OVERWRITE_SKILLS" == "true" ]]; then
  BOOTSTRAP_NONINTERACTIVE=1 INSTALL_SKILLS_OVERWRITE=1 run_step "Installing skills" bash "$SCRIPT_DIR/install-skills.sh" --overwrite
else
  BOOTSTRAP_NONINTERACTIVE=1 run_step "Installing skills" bash "$SCRIPT_DIR/install-skills.sh"
fi
run_step "Installing plugins" bash "$SCRIPT_DIR/install-plugins.sh"
run_step "Verifying installation" bash "$SCRIPT_DIR/verify-install.sh"

printf '\nBootstrap complete.\n'
