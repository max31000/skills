# AI Environment Bootstrap Repository

This repository is a cross-platform bootstrap source of truth for restoring AI coding environments on new machines.

It manages:
- packages and CLI dependencies
- tool/runtime versions
- Claude Code and OpenCode config
- curated external skills
- local custom skills
- plugin install manifests
- repo-owned commands and agents
- repository-owned custom plugin content

## Quick Start

**macOS / Linux:**
```bash
bash bootstrap.sh
```

Force-refresh installed skills during bootstrap:

```bash
bash bootstrap.sh --overwrite-skills
```

Use `bash bootstrap.sh`, not `./bootstrap.sh`. This avoids executable-permission issues on fresh clones.

Bootstrap now prints a preflight plan before it changes anything, skips dependencies that are already satisfied, attempts updates only for outdated items, and writes verbose installer output to `.bootstrap-logs/<timestamp>/`. It stops when a required dependency still cannot be provided for later required steps.

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File bootstrap.ps1
```

Force-refresh installed skills during bootstrap:

```powershell
powershell -ExecutionPolicy Bypass -File bootstrap.ps1 -OverwriteSkills
```

## Repository Layout

- `manifest/` — declarative desired state for packages, tools, plugins, targets, skills, commands, and agents
- `assets/` — shared and target-specific config assets
- `custom-skills/` — repository-owned custom skills
- `scripts/` — bootstrap, install, render, and verify entrypoints
- `docs/` — architecture and restore flow docs

## Current Functionality

- installs or updates direct AI-agent dependencies only when needed, with concise terminal output and detailed logs
- renders Claude Code and OpenCode config
- installs curated external skills and local custom skills
- renders repo-owned commands and agents with target-specific overrides
- runs optional plugin backends such as `compound-engineering` when prerequisites exist
- verifies the resulting Claude/OpenCode paths

## What Gets Installed

| Source | Skills |
|--------|--------|
| [anthropics/skills](https://github.com/anthropics/skills) | skill-creator, frontend-design, webapp-testing, mcp-builder, internal-comms, doc-coauthoring, algorithmic-art, brand-guidelines, canvas-design, claude-api, slack-gif-creator, theme-factory, web-artifacts-builder |
| [obra/superpowers](https://github.com/obra/superpowers) | brainstorming, test-driven-development, systematic-debugging, subagent-driven-development, writing-plans, executing-plans, dispatching-parallel-agents, using-git-worktrees, requesting-code-review, receiving-code-review, finishing-a-development-branch, verification-before-completion, writing-skills, using-superpowers |
| [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) | planning-with-files |
| [richlander/dotnet-skills](https://github.com/richlander/dotnet-skills) | dotnet-inspect |
| [addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills) | web-quality-audit, performance, accessibility, core-web-vitals, best-practices, seo |
| Custom (local) | batch-operations, changelog-generator, colony-sim, cpp-graphics, docker-helper, ffmpeg, game-testing, github-actions, godot, react-typescript, security-audit, simplify-refactor, sql-helper |

> **Note:** Built-in Claude Code skills (`anthropic-skills:pdf`, `xlsx`, `pptx`, `docx`, `schedule`) are not installed here — they ship with Claude Code.

## Current Curation

- Workflow and process conflicts are resolved in favor of established external skill sets.
- `obra/superpowers` replaces the local debugging and code-review workflow skills.
- Domain-specific local skills remain when they add coverage not provided by the external sets.
- `dotnet/skills` is intentionally not installed yet because this project does not currently support plugin-style repositories.

## Current Plugin Support

- Skill-folder repositories are installed directly by `scripts/install-skills.sh` and `scripts/install-skills.ps1`.
- Plugin installs are declared in `manifest/plugins/plugins.manifest.json` and executed through `scripts/plugin_backend.py`.
- `compound-engineering-plugin` is modeled through a `compound-bunx` backend with preflight checks, target validation, and expected-path verification. It is enabled by default as an optional plugin: if `bunx` or network access is missing, the bootstrap skips it without failing the whole run.
- `dotnet/skills` remains modeled as a manual plugin because its public docs still center on `/plugin` installation.

## `install-skills.sh`

`install-skills.sh` and `install-skills.ps1` are still useful as narrower entrypoints when you only want to refresh skills without running the full bootstrap. The full setup should normally use `bootstrap.sh` or `bootstrap.ps1`.

Explicit overwrite examples:

```bash
bash install-skills.sh --overwrite
```

```powershell
powershell -ExecutionPolicy Bypass -File install-skills.ps1 -Overwrite
```

## Current Limitation: Native Plugin APIs

The installers currently support repositories that expose installable skill folders containing `SKILL.md` files.

Supported today:
- Direct skill folders under the configured `src_subdir`
- Fallback skill folders under repo-level `skills/`
- Local custom skills under `custom-skills/<name>/SKILL.md`

Not supported yet:
- Plugin manifests such as `plugin.json`
- Agent bundles
- Slash commands / workflows
- MCP server configuration
- Provider-specific conversion pipelines such as `bunx ... install --to copilot`

That means repositories like `dotnet/skills` still need either a documented non-interactive plugin installer or future native plugin support in this repo.

## Packages and Tools

- macOS packages are declared in `manifest/packages/Brewfile`
- Windows packages are declared in `manifest/packages/winget-packages.json`
- runtime/tool versions are declared in `manifest/tools/mise.toml`

Bootstrap scripts install what they can and skip missing package managers with a clear message.

The default install UX is intentionally quiet:
- preflight shows what is already OK, what will be installed, and what will be updated
- already-satisfied dependencies are skipped
- outdated dependencies are updated instead of blindly reinstalled
- verbose package-manager and tool-manager output is written to `.bootstrap-logs/`
- required dependency failures stop the run; optional failures are surfaced as warnings with a log path

## Config Rendering

- Claude Code config is rendered to `~/.claude/settings.json`
- OpenCode config is rendered to `~/.config/opencode/opencode.json`
- repo-owned commands are rendered from `manifest/commands/commands.manifest.json`
- repo-owned agents are rendered from `manifest/agents/agents.manifest.json`
- target-specific assets in `assets/claude/*` and `assets/opencode/*` automatically override shared assets with the same relative path
- Claude Code config is also managed conservatively: bootstrap preserves an existing `settings.json` and does not inject extra keys, because unsupported fields can prevent Claude Code from launching
- OpenCode config is intentionally managed conservatively: bootstrap preserves an existing `opencode.json` and only ensures the `$schema` key exists, because unsupported keys can break local launch

## Scope

This repository intentionally focuses on AI agent environments and their direct dependencies only. It does not try to fully synchronize entire workstations or unrelated personal dotfiles.

## Adding Your Own Skills

### Custom skill (local)

Create `custom-skills/<skill-name>/SKILL.md`:

```markdown
---
name: my-skill
description: >
  When to trigger this skill. Include keywords the user might say.
---

# My Skill

Instructions for the agent...
```

The skill installers pick it up automatically — no script edits needed.

### External repo

Add a line to `manifest/skills/repos.conf`:

```
https://github.com/user/repo.git|repo-name|skills|skill-a,skill-b
```

Format: `repo_url|clone_name|src_subdir|skill1,skill2,...`

This works for repositories that expose raw skill directories. Plugin-based repositories should be declared in `manifest/plugins/plugins.manifest.json`.

## Verification

- macOS/Linux: `bash scripts/verify-install.sh`
- Windows: `powershell -ExecutionPolicy Bypass -File scripts/verify-install.ps1`

Verification currently checks config, skills, commands, and agent output paths for Claude Code and OpenCode.

## Uninstall

```bash
rm -rf ~/.claude/skills ~/.config/opencode/skills
```

Or on Windows PowerShell:
```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\skills", "$env:USERPROFILE\.config\opencode\skills"
```
