# Universal Agent Skills Installer

Installs a curated set of skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [OpenCode](https://github.com/opencode-ai/opencode).

Skills are installed to `~/.claude/skills/` (primary) and symlinked/copied to `~/.config/opencode/skills/`.

## Quick Start

**macOS / Linux:**
```bash
bash install-skills.sh
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File install-skills.ps1
```

## What Gets Installed

| Source | Skills |
|--------|--------|
| [anthropics/skills](https://github.com/anthropics/skills) | skill-creator, frontend-design, webapp-testing, mcp-builder, internal-comms, doc-coauthoring, algorithmic-art, brand-guidelines, canvas-design, claude-api, slack-gif-creator, theme-factory, web-artifacts-builder |
| [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) | planning-with-files |
| [addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills) | web-quality-audit, performance, accessibility, core-web-vitals, best-practices, seo |
| Custom (local) | code-review, debug-workflow, simplify-refactor, security-audit, docker-helper, sql-helper, github-actions, react-typescript, changelog-generator, batch-operations, godot, ffmpeg, cpp-graphics |

> **Note:** Built-in Claude Code skills (`anthropic-skills:pdf`, `xlsx`, `pptx`, `docx`, `schedule`) are not installed here — they ship with Claude Code.

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

Both installers pick it up automatically — no script edits needed.

### External repo

Add a line to `repos.conf`:

```
https://github.com/user/repo.git|repo-name|skills|skill-a,skill-b
```

Format: `repo_url|clone_name|src_subdir|skill1,skill2,...`

## Uninstall

```bash
rm -rf ~/.claude/skills ~/.config/opencode/skills
```

Or on Windows PowerShell:
```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\skills", "$env:USERPROFILE\.config\opencode\skills"
```
