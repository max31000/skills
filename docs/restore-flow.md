# Restore Flow

## macOS / Linux

```bash
bash bootstrap.sh
```

Overwrite already installed skills during bootstrap:

```bash
bash bootstrap.sh --overwrite-skills
```

Use `bash bootstrap.sh` instead of `./bootstrap.sh` so the repo works even when execute bits are not preserved by the clone/archive.

## Windows

```powershell
powershell -ExecutionPolicy Bypass -File bootstrap.ps1
```

Overwrite already installed skills during bootstrap:

```powershell
powershell -ExecutionPolicy Bypass -File bootstrap.ps1 -OverwriteSkills
```

## What Happens

1. Bootstrap prints a preflight summary of packages and tools to skip, install, or update.
2. Packages are selectively installed or updated with the platform package manager.
3. Tool versions are selectively installed or updated with `mise`.
4. Claude Code and OpenCode config files are rendered.
5. Repo-owned commands and agents are rendered.
6. Curated skills are installed.
7. Plugin backends are executed when enabled and available.
8. Verification checks report the resulting state.

Verbose installer output is written to `.bootstrap-logs/<timestamp>/` so the default terminal output stays concise.

Bootstrap stops when a required dependency remains unavailable for later required steps. Optional dependency failures are reported as warnings.

## Skills-Only Refresh

If you only need to refresh installed skills:

```bash
bash install-skills.sh
```

```bash
bash install-skills.sh --overwrite
```

```powershell
powershell -ExecutionPolicy Bypass -File install-skills.ps1
```

```powershell
powershell -ExecutionPolicy Bypass -File install-skills.ps1 -Overwrite
```
