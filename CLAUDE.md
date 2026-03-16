# Universal Agent Skills Installer

Cross-platform installer (bash + PowerShell) that installs skills for Claude Code and OpenCode.

## Project Structure

- `repos.conf` — shared config listing external GitHub repos and which skills to install from each. Pipe-delimited format: `repo_url|clone_name|src_subdir|skill1,skill2,...`
- `custom-skills/<name>/SKILL.md` — local custom skill definitions. Each is a directory with a single SKILL.md file.
- `install-skills.sh` — bash installer for macOS/Linux/Git Bash
- `install-skills.ps1` — PowerShell installer for Windows
- Both scripts read the same `repos.conf` and `custom-skills/` directory — this is the single source of truth.

## Key Rules

- **Both scripts must stay in sync.** If you change installation logic, update both `install-skills.sh` and `install-skills.ps1`.
- **Never hardcode skill lists in the scripts.** All skill data comes from `repos.conf` (external repos) and `custom-skills/` (local skills).
- **Adding a skill should never require editing the scripts.** New custom skill = new directory in `custom-skills/`. New external repo = new line in `repos.conf`.

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

## repos.conf Format

```
# Lines starting with # are comments. Blank lines are ignored.
# Fields: repo_url|clone_name|src_subdir|skill1,skill2,...
https://github.com/user/repo.git|repo-name|skills|skill-a,skill-b
```

The `install_from_repo` function tries `src_subdir` first, then falls back to `skills/` subdirectory if the skill isn't found at the configured path.
