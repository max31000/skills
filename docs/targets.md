# Target Differences

## Claude Code

- Skills live in `~/.claude/skills/`
- Settings live in `~/.claude/settings.json`
- Commands live in `~/.claude/commands/`
- Agents live in `~/.claude/agents/`
- Bootstrap keeps Claude config minimal and avoids injecting unsupported keys
- Some plugins still require `/plugin` workflows

## OpenCode

- Skills live in `~/.config/opencode/skills/`
- Config lives in `~/.config/opencode/opencode.json`
- Commands live in `~/.config/opencode/commands/`
- Bootstrap keeps OpenCode config minimal and avoids injecting unsupported keys
- Plugin-compatible sync can be delegated to `compound-plugin` when available
