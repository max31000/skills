#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="${BOOTSTRAP_LOG_DIR:-$ROOT_DIR/.bootstrap-logs/manual}"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'FAIL: required dependency `python3` is unavailable.\n'
  printf 'Bootstrap cannot continue because package planning depends on it.\n'
  exit 1
fi

mkdir -p "$LOG_DIR"

RESULT_FILE="$LOG_DIR/install-packages.json"
python3 "$SCRIPT_DIR/bootstrap_deps.py" install-packages --root "$ROOT_DIR" --log-dir "$LOG_DIR" >"$RESULT_FILE" || status=$?
status=${status:-0}

python3 - "$RESULT_FILE" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
for line in payload.get("lines", []):
    print(line)
PY

exit "$status"
