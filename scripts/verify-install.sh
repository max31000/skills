#!/usr/bin/env bash
set -euo pipefail

check_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    printf 'OK: %s\n' "$path"
  else
    printf 'WARN: missing %s\n' "$path"
  fi
}

check_path "$HOME/.claude/settings.json"
check_path "$HOME/.claude/skills"
check_path "$HOME/.claude/commands"
check_path "$HOME/.claude/agents"
check_path "$HOME/.claude/commands/bootstrap-status.md"
check_path "$HOME/.claude/agents/bootstrap-maintainer.md"
check_path "$HOME/.config/opencode/opencode.json"
check_path "$HOME/.config/opencode/skills"
check_path "$HOME/.config/opencode/commands"
check_path "$HOME/.config/opencode/commands/bootstrap-status.md"
