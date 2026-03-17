# AI Environment Bootstrap Repository

Cross-platform bootstrap repository for restoring Claude Code and OpenCode environments with packages, tools, settings, skills, and plugin declarations.

## Project Structure

- `manifest/skills/repos.conf` — shared config listing external GitHub repos and which skills to install from each. Pipe-delimited format: `repo_url|clone_name|src_subdir|skill1,skill2,...`
- `manifest/packages/` — declarative package manager inputs per platform
- `manifest/tools/mise.toml` — tool and runtime version declarations
- `manifest/plugins/plugins.manifest.json` — plugin install declarations and target support
- `manifest/targets/` — target metadata for Claude Code and OpenCode
- `assets/` — shared and target-specific config assets
- `custom-skills/<name>/SKILL.md` — local custom skill definitions. Each is a directory with a single SKILL.md file.
- `scripts/bootstrap.sh` / `scripts/bootstrap.ps1` — primary one-command entrypoints
- `scripts/install-skills.sh` / `scripts/install-skills.ps1` — skill installers
- `scripts/` — package, tool, plugin, render, and verification scripts
- top-level `bootstrap.*` and `install-skills.*` — compatibility wrappers that should work even when execute bits are missing

## Key Rules

- **Both platform entrypoints must stay in sync.** If you change installation logic, update the bash and PowerShell variants together.
- **Prefer declarative manifests over hardcoding.** Packages, tools, plugins, targets, and external skills belong in `manifest/`.
- **Adding a custom skill should not require script edits.** New custom skill = new directory in `custom-skills/`.
- **Adding a simple external skill repo should not require script edits.** New skill repo = new line in `manifest/skills/repos.conf`.
- **Current support is skill-folder based only.** Repositories must expose installable directories containing `SKILL.md`. Plugin-style repos with `plugin.json`, agents, commands, MCP config, or provider-specific installers are not supported until both scripts are extended together.
- **When workflow skills conflict, prefer established external repos over local custom duplicates.** Keep local custom skills for domain-specific gaps only.
- **Prefer external installer backends when they exist.** For example, use `compound-plugin` conversion/sync instead of reimplementing those target transforms.

## SKILL.md Format

```markdown
---
name: skill-id
description: >
  When to trigger. Include trigger keywords.
---

# Skill Title

Instructions for the agent...
```

## `repos.conf` Format

```
# Lines starting with # are comments. Blank lines are ignored.
# Fields: repo_url|clone_name|src_subdir|skill1,skill2,...
https://github.com/user/repo.git|repo-name|skills|skill-a,skill-b
```

The `install_from_repo` function tries `src_subdir` first, then falls back to `skills/` subdirectory if the skill isn't found at the configured path.
