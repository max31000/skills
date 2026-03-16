#!/usr/bin/env bash
# ============================================================================
#  Universal Agent Skills Installer
#  Works on: macOS (bash/zsh), Linux, Windows (Git Bash / WSL)
#  Installs to: ~/.claude/skills/  (primary, seen by Claude Code + OpenCode)
#  Symlinks to: ~/.config/opencode/skills/  (OpenCode native path)
#
#  Note: anthropic-skills:* (pdf, xlsx, pptx, docx, schedule) are built-in
#  to Claude Code and do not require manual installation here.
# ============================================================================
set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $1"; exit 1; }

# ── Pre-flight checks ──────────────────────────────────────────────────────
command -v git  >/dev/null 2>&1 || fail "git is not installed"
command -v curl >/dev/null 2>&1 || fail "curl is not installed"

# ── Full list of skills this script installs ─────────────────────────────────
# Used upfront to detect existing installs and ask about overwriting.
ALL_SKILLS=(
    # Official Anthropic
    skill-creator frontend-design webapp-testing mcp-builder
    internal-comms doc-coauthoring keybindings-help simplify
    # Planning
    planning-with-files
    # Web Quality
    web-quality-audit performance accessibility core-web-vitals best-practices seo
    # Custom Workflow
    code-review debug-workflow simplify-refactor security-audit
    docker-helper sql-helper github-actions react-typescript
    changelog-generator batch-operations
    # Tech Stack
    godot ffmpeg cpp-graphics
)

# ── Paths ───────────────────────────────────────────────────────────────────
SKILLS_DIR="$HOME/.claude/skills"
OPENCODE_DIR="$HOME/.config/opencode/skills"
TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'skills-install')

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

mkdir -p "$SKILLS_DIR"
mkdir -p "$OPENCODE_DIR"

info "Skills directory:   $SKILLS_DIR"
info "OpenCode symlink:   $OPENCODE_DIR"
echo ""

# ── Overwrite check ──────────────────────────────────────────────────────────
existing=()
for s in "${ALL_SKILLS[@]}"; do
    [ -d "$SKILLS_DIR/$s" ] && [ -f "$SKILLS_DIR/$s/SKILL.md" ] && existing+=("$s")
done

OVERWRITE=false
if [ ${#existing[@]} -gt 0 ]; then
    echo -e "${YELLOW}Already installed (${#existing[@]}):${NC}"
    for s in "${existing[@]}"; do printf "    %s\n" "$s"; done
    echo ""
    printf "Overwrite existing skills? [y/N] "
    read -r answer </dev/tty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        OVERWRITE=true
        ok "Existing skills will be overwritten."
    else
        info "Existing skills will be skipped. Only new skills will be installed."
    fi
    echo ""
fi

# ── Helper: clone a repo and copy specific skill folders ────────────────────
install_from_repo() {
    local repo_url="$1"
    local repo_name="$2"
    local src_subdir="$3"
    shift 3
    local skill_dirs=("$@")

    info "Cloning $repo_name..."
    git clone --depth 1 --quiet "$repo_url" "$TMP_DIR/$repo_name" 2>/dev/null || {
        warn "Failed to clone $repo_name — skipping"
        return 0
    }

    local base_path="$TMP_DIR/$repo_name"
    [ "$src_subdir" != "." ] && base_path="$base_path/$src_subdir"

    for skill in "${skill_dirs[@]}"; do
        if [ -d "$SKILLS_DIR/$skill" ] && [ -f "$SKILLS_DIR/$skill/SKILL.md" ] && [ "$OVERWRITE" = "false" ]; then
            info "  ~ $skill (skipped)"
            continue
        fi
        if [ -d "$base_path/$skill" ] && [ -f "$base_path/$skill/SKILL.md" ]; then
            rm -rf "$SKILLS_DIR/$skill"
            cp -r "$base_path/$skill" "$SKILLS_DIR/$skill"
            ok "  + $skill"
        else
            warn "  ! $skill — SKILL.md not found in repo, skipping"
        fi
    done
}

# ── Helper: create a custom skill from inline content ───────────────────────
create_skill() {
    local name="$1"
    local content="$2"
    if [ -d "$SKILLS_DIR/$name" ] && [ -f "$SKILLS_DIR/$name/SKILL.md" ] && [ "$OVERWRITE" = "false" ]; then
        info "  ~ $name (skipped)"
        return
    fi
    mkdir -p "$SKILLS_DIR/$name"
    printf '%s\n' "$content" > "$SKILLS_DIR/$name/SKILL.md"
    ok "  + $name (custom)"
}

# ============================================================================
#  1. OFFICIAL ANTHROPIC SKILLS
# ============================================================================
echo -e "${CYAN}--- Official Anthropic Skills ---${NC}"
install_from_repo \
    "https://github.com/anthropics/skills.git" \
    "anthropics-skills" \
    "skills" \
    "skill-creator" \
    "frontend-design" \
    "webapp-testing" \
    "mcp-builder" \
    "internal-comms" \
    "doc-coauthoring" \
    "keybindings-help" \
    "simplify"
echo ""

# ============================================================================
#  2. PLANNING & WORKFLOW (planning-with-files — 13k+ stars)
# ============================================================================
echo -e "${CYAN}--- Planning & Workflow ---${NC}"

if [ -d "$SKILLS_DIR/planning-with-files" ] && [ -f "$SKILLS_DIR/planning-with-files/SKILL.md" ] && [ "$OVERWRITE" = "false" ]; then
    info "  ~ planning-with-files (skipped)"
else
    info "Cloning planning-with-files..."
    if git clone --depth 1 --quiet "https://github.com/OthmanAdi/planning-with-files.git" "$TMP_DIR/pwf" 2>/dev/null; then
        if [ -d "$TMP_DIR/pwf/planning-with-files" ] && [ -f "$TMP_DIR/pwf/planning-with-files/SKILL.md" ]; then
            rm -rf "$SKILLS_DIR/planning-with-files"
            cp -r "$TMP_DIR/pwf/planning-with-files" "$SKILLS_DIR/planning-with-files"
            ok "  + planning-with-files"
        elif [ -d "$TMP_DIR/pwf/skills/planning-with-files" ] && [ -f "$TMP_DIR/pwf/skills/planning-with-files/SKILL.md" ]; then
            rm -rf "$SKILLS_DIR/planning-with-files"
            cp -r "$TMP_DIR/pwf/skills/planning-with-files" "$SKILLS_DIR/planning-with-files"
            ok "  + planning-with-files (from skills/)"
        else
            warn "  ! planning-with-files — could not locate SKILL.md"
        fi
    else
        warn "Failed to clone planning-with-files"
    fi
fi
echo ""

# ============================================================================
#  3. WEB QUALITY (Addy Osmani — Lighthouse, Core Web Vitals, a11y, SEO)
# ============================================================================
echo -e "${CYAN}--- Web Quality Skills (Addy Osmani) ---${NC}"
install_from_repo \
    "https://github.com/addyosmani/web-quality-skills.git" \
    "web-quality-skills" \
    "skills" \
    "web-quality-audit" \
    "performance" \
    "accessibility" \
    "core-web-vitals" \
    "best-practices" \
    "seo"
echo ""

# ============================================================================
#  4. CUSTOM WORKFLOW SKILLS
# ============================================================================
echo -e "${CYAN}--- Custom Workflow Skills ---${NC}"

# ── Code Review ─────────────────────────────────────────────────────────────
create_skill "code-review" '---
name: code-review
description: >
  Structured code review for pull requests and local changes.
  Use when the user asks to review code, review a PR, check changes,
  find issues in code, or says "review", "CR", "code review", "check my code".
---

# Code Review

Perform a structured, multi-pass code review of the provided code or changes.

## Review Process

1. **Understand scope** — read the diff or files. Identify what changed and why.
2. **Correctness pass** — look for bugs, logic errors, off-by-one, null refs, race conditions.
3. **Security pass** — check for injection, auth issues, secrets in code, unsafe deserialization.
4. **Design pass** — SOLID violations, god classes, tight coupling, missing abstractions.
5. **Maintainability pass** — naming, readability, dead code, overly complex expressions.
6. **Test coverage** — are changes covered by tests? Are edge cases tested?

## Output Format

For each finding, provide:
- **File and line** (if applicable)
- **Severity**: [КРИТИЧНО] / [ВАЖНО] / [НЕЗНАЧИТЕЛЬНО] / [ПРЕДЛОЖЕНИЕ]
- **Description**: What the issue is
- **Fix**: Concrete suggestion

End with a summary: total findings by severity, overall assessment (approve / request changes).

## Guidelines
- Be specific. "This could be better" is not useful. Show the fix.
- Praise good patterns — not everything is negative.
- For C# / ASP.NET: async/await misuse, IDisposable leaks, LINQ performance,
  missing CancellationToken, middleware ordering, minimal API vs controller tradeoffs.
- For React/TS: hook dependencies, memo boundaries, type safety, key props.
- For both: check error handling completeness and logging quality.
'

# ── Debug Workflow ──────────────────────────────────────────────────────────
create_skill "debug-workflow" '---
name: debug-workflow
description: >
  Systematic debugging methodology. Use when the user reports a bug,
  error, exception, unexpected behavior, or says "debug", "fix this",
  "why is this failing", "trace the issue", "root cause".
---

# Debug Workflow

Apply a systematic debugging approach. Never guess — always gather evidence first.

## Process

### 1. Reproduce
- Confirm the exact steps to reproduce the issue.
- Identify: expected behavior vs actual behavior.
- Note the environment (OS, runtime version, config).

### 2. Isolate
- Narrow down: which file, function, or line causes the failure?
- Use binary search: comment out halves of the code to locate the source.
- Check recent changes: `git log --oneline -20`, `git diff`.

### 3. Analyze root cause
- Read the full error message and stack trace carefully.
- Check: is this a symptom or the actual cause?
- Common root causes: null/undefined, wrong type, race condition, stale state,
  missing await, wrong config/env variable, dependency version mismatch.

### 4. Fix and verify
- Apply the minimal fix that addresses the root cause (not the symptom).
- Run the failing test / repro steps to confirm the fix.
- Check for regressions: run the full relevant test suite.

### 5. Prevent recurrence
- Suggest a test that would have caught this.
- Note if a linter rule or type constraint could prevent similar issues.

## Anti-patterns to avoid
- Do NOT apply random fixes hoping something sticks.
- Do NOT change multiple things at once — one change at a time.
- Do NOT skip reading the actual error message.
'

# ── Simplify & Refactor (aligned with built-in `simplify` skill purpose) ────
create_skill "simplify-refactor" '---
name: simplify-refactor
description: >
  Review changed code for reuse, quality, and efficiency, then fix any issues found.
  Use when the user asks to simplify code, refactor, clean up, reduce complexity,
  remove duplication, improve readability, or says "simplify", "refactor",
  "clean this up", "make this better", "reduce complexity".
---

# Simplify & Refactor

Review changed or provided code for reuse, quality, and efficiency. Fix all issues found.

## Review Checklist

1. **Reuse** — is there logic that already exists and should be called instead?
   Extract shared logic into helpers. Prefer existing utilities over reinventing.

2. **Quality**
   - Dead code: unused variables, unreachable branches, commented-out blocks.
   - Naming: unclear names, inconsistent conventions.
   - Unnecessary abstraction: interfaces with one implementation, wrapper-only classes.
   - Complexity: deeply nested ifs, methods >30 lines, god classes.

3. **Efficiency**
   - Redundant computations inside loops.
   - Allocations that can be avoided or pooled.
   - N+1 query patterns in data access.
   - Language idioms:
     - C#: LINQ over manual loops, pattern matching, nullable reference types, `Span<T>` for hot paths.
     - TypeScript: optional chaining, nullish coalescing, discriminated unions.
     - React: derived state over extra useState, stable references to avoid re-renders.

## Rules
- **Preserve behavior.** Every change must be behavior-preserving. Run tests after.
- **One concern at a time.** Do not combine rename + extract + restructure in one step.
- **Explain each fix.** State why it is simpler or more efficient — fewer lines is not always simpler.
- **Respect conventions.** Match the codebase style; do not introduce new paradigms.
- **Apply the fix.** Do not just list issues — make the actual changes.
'

# ── Security Audit ──────────────────────────────────────────────────────────
# Note: addyosmani/best-practices covers frontend security (CSP, HSTS, headers).
# This skill focuses on backend/API security: OWASP, auth, data protection, CVEs.
create_skill "security-audit" '---
name: security-audit
description: >
  Security review and vulnerability scanning for codebases.
  Use when the user asks for security review, audit, vulnerability check,
  or mentions "security", "vulnerabilities", "OWASP", "pentest", "CVE",
  "secrets scan", "dependency audit".
---

# Security Audit

Perform a structured security review of the codebase or specific changes.

## Review Areas

### Input Validation & Injection
- SQL injection (parameterized queries? ORM misuse?)
- XSS (user input rendered without sanitization?)
- Command injection (shell exec with user input?)
- Path traversal (user-controlled file paths?)

### Authentication & Authorization
- Auth bypass possibilities
- Missing authorization checks on endpoints
- Hardcoded credentials or API keys
- JWT issues (none algorithm, weak secret, no expiry)
- ASP.NET: `[Authorize]` coverage, policy-based auth correctness, cookie security flags

### Data Protection
- Sensitive data in logs or error messages
- PII exposure in API responses
- Missing encryption for data at rest / in transit
- Secrets in source code or config files
- ASP.NET: Data Protection API usage, connection string exposure, HTTPS enforcement

### Dependencies
- Known CVEs in dependencies (check package.json, *.csproj)
- Outdated packages with security patches available
- Typosquatting risk in package names

### Configuration
- Debug mode / detailed errors enabled in production
- CORS misconfiguration
- Missing security headers (CSP, HSTS, X-Frame-Options)
- Default credentials or open admin panels

## Output
For each finding:
- **Risk**: Critical / High / Medium / Low / Info
- **Location**: file:line
- **Issue**: what is vulnerable
- **Impact**: what an attacker could do
- **Remediation**: specific fix with code example
'

# ── Docker Helper ───────────────────────────────────────────────────────────
create_skill "docker-helper" '---
name: docker-helper
description: >
  Docker and container operations. Use when the user works with Docker,
  Dockerfile, docker-compose, containers, images, or mentions
  "docker", "container", "dockerfile", "compose", "image build".
---

# Docker Helper

Assist with Docker-related tasks: writing Dockerfiles, docker-compose configs,
debugging container issues, and optimizing images.

## Dockerfile Best Practices
- Use specific base image tags (not :latest).
- Order layers from least to most frequently changed.
- Combine RUN commands to reduce layers.
- Use multi-stage builds for compiled languages (C#, Go, Rust).
- Add .dockerignore to exclude build artifacts, node_modules, bin/obj.
- Run as non-root user in production images.
- Use COPY over ADD unless extracting archives.

## ASP.NET Core Specific
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app
COPY --from=build /app .
USER app
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

## React/Node Specific
```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
RUN yarn build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

## Debugging Containers
- `docker logs <container>` — check output
- `docker exec -it <container> sh` — shell into running container
- `docker inspect <container>` — network, mounts, env
- `docker stats` — resource usage
- `docker system df` — disk usage
'

# ── SQL / Database Helper ───────────────────────────────────────────────────
create_skill "sql-helper" '---
name: sql-helper
description: >
  SQL and database operations. Use when the user works with SQL queries,
  database schema, migrations, or mentions "SQL", "query", "database",
  "migration", "schema", "index", "stored procedure", "PostgreSQL",
  "MSSQL", "MySQL", "Entity Framework", "EF Core".
---

# SQL & Database Helper

Assist with writing, optimizing, and debugging SQL and database operations.

## Query Writing
- Always use parameterized queries — never string concatenation.
- Prefer explicit column lists over SELECT *.
- Use CTEs for readability over deeply nested subqueries.
- Add table aliases for any query with joins.

## Performance Optimization
- Check execution plans (EXPLAIN / SET STATISTICS IO ON).
- Look for: table scans, missing indexes, implicit conversions, N+1 queries.
- Index strategy: cover the WHERE, JOIN, and ORDER BY columns.
- Avoid functions on indexed columns in WHERE (breaks index usage).
- For pagination: use keyset (WHERE id > @lastId) over OFFSET/FETCH for large datasets.

## EF Core / .NET Specific
- Use `.AsNoTracking()` for read-only queries.
- Avoid `.ToList()` before filtering — let the DB do the work.
- Use `IQueryable` projections (`.Select()`) to fetch only needed columns.
- Beware of lazy loading N+1 — use `.Include()` or split queries.
- Migrations: always review generated SQL before applying.

## Schema Design
- Use appropriate data types (do not store dates as strings).
- Add NOT NULL constraints by default, allow NULL only when semantically required.
- Foreign keys for referential integrity.
- Consider soft deletes (IsDeleted flag) vs hard deletes based on domain.

## Common Anti-patterns
- SELECT * in production code
- Missing indexes on foreign keys
- Using LIKE with leading wildcard (kills index)
- Storing comma-separated values instead of proper relations
- Not handling NULL in comparisons (NULL != NULL)
'

# ── GitHub Actions ──────────────────────────────────────────────────────────
create_skill "github-actions" '---
name: github-actions
description: >
  GitHub Actions CI/CD workflows. Use when the user works with GitHub Actions,
  CI/CD pipelines, workflow files, or mentions "github actions", "GHA",
  "workflow", "CI", "CD", "pipeline", ".github/workflows".
---

# GitHub Actions

Assist with creating, debugging, and optimizing GitHub Actions workflows.

## Workflow Structure
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: 9.0.x
      - run: dotnet build
      - run: dotnet test
```

## Best Practices
- Pin action versions to full SHA or major version (actions/checkout@v4).
- Use caching (actions/cache) for NuGet, npm, yarn to speed up builds.
- Set `concurrency` to cancel in-progress runs on same PR.
- Use `needs:` for job dependencies, not implicit ordering.
- Store secrets in GitHub Secrets, reference via `${{ secrets.NAME }}`.
- Use matrix strategy for testing across multiple runtimes/OS.

## .NET Specific Patterns
- Cache NuGet: `actions/cache` with `~/.nuget/packages` path.
- Use `dotnet test --logger trx --results-directory TestResults` + publish test results.
- For deploy: `dotnet publish -c Release -o ./publish`.

## React/Node Patterns
- Cache node_modules via `actions/setup-node` built-in caching.
- Run `yarn install --frozen-lockfile` (or `npm ci`).
- Lint → Type-check → Test → Build (fail fast order).

## Debugging
- Use `ACTIONS_RUNNER_DEBUG: true` in secrets for verbose logs.
- Add `run: env` step to inspect environment.
- Use `act` locally to test workflows without pushing.
'

# ── React + TypeScript Best Practices ───────────────────────────────────────
create_skill "react-typescript" '---
name: react-typescript
description: >
  React and TypeScript best practices and patterns. Use when the user
  writes React components with TypeScript, or asks about React patterns,
  hooks, state management, component design, or mentions "React", "TSX",
  "hooks", "component", "useState", "useEffect", "TypeScript + React".
---

# React + TypeScript Best Practices

## Component Design
- Prefer function components with hooks over class components.
- One component per file. File name matches component name.
- Props interface: `interface FooProps { ... }` — exported if reused, inline if local.
- Use `React.FC` sparingly — prefer explicit return types or none.
- Destructure props in the function signature.

## Type Safety
- Never use `any`. Use `unknown` + type narrowing if type is uncertain.
- Use discriminated unions for state variants:
  ```ts
  type State =
    | { status: "idle" }
    | { status: "loading" }
    | { status: "error"; error: string }
    | { status: "success"; data: Data };
  ```
- Use `as const` for literal objects and `satisfies` for type checking without widening.
- Generics for reusable hooks and components.

## Hooks
- Keep hooks flat — avoid deeply nested custom hooks calling custom hooks.
- `useEffect` dependency arrays must be complete. If a dep changes too often, rethink the design.
- Prefer derived state (compute from existing state) over extra `useState`.
- Custom hooks: prefix with `use`, return a tuple or named object.
- Memoization (`useMemo`, `useCallback`): use only when profiling shows a need.

## State Management
- Local state (`useState`) for component-scoped data.
- Lift state only when siblings need it — no premature lifting.
- Context for low-frequency global state (theme, auth, locale).
- External store (Zustand, Redux, etc.) for high-frequency shared state.

## Performance
- Code-split routes with `React.lazy` + `Suspense`.
- Virtualize long lists (react-window / tanstack-virtual).
- Avoid inline object/function creation in JSX when passed as props.
- Use React DevTools Profiler to find actual bottlenecks before optimizing.

## Testing
- Test behavior, not implementation.
- Use React Testing Library — query by role, label, text (not test-id as first choice).
- Test user flows, not individual hooks.
'

# ── Changelog Generator ────────────────────────────────────────────────────
create_skill "changelog-generator" '---
name: changelog-generator
description: >
  Generate changelogs from git history. Use when the user asks to create
  a changelog, release notes, version summary, or says "changelog",
  "release notes", "what changed", "generate changelog".
---

# Changelog Generator

Generate a human-readable changelog from git commit history.
Output language: Russian.

## Process

1. Determine the version range:
   - Ask: between which tags/commits? Default: last tag to HEAD.
   - `git log --oneline <from>..<to>`

2. Categorize commits by conventional commit prefix:
   - feat:             -> Новые возможности
   - fix:              -> Исправления ошибок
   - perf:             -> Производительность
   - refactor:         -> Рефакторинг
   - docs:             -> Документация
   - test:             -> Тесты
   - chore/ci/build:   -> Обслуживание
   - BREAKING CHANGE:  -> Критические изменения (выделить в начале)

3. For each entry:
   - Rewrite the commit message into user-facing language in Russian.
   - Remove technical jargon. Focus on what changed for the user.
   - Include PR number if available.

4. Output format:
```markdown
## [X.Y.Z] - ГГГГ-ММ-ДД

### Критические изменения
- Описание (#PR)

### Новые возможности
- Описание (#PR)

### Исправления ошибок
- Описание (#PR)

### Производительность
- Описание (#PR)

### Рефакторинг
- Описание (#PR)

### Обслуживание
- Описание (#PR)
```

## Guidelines
- Skip merge commits and chore commits unless significant.
- Group related changes into single entries.
- Omit sections with no entries.
- If no conventional commits: infer category from the diff content.
- Write all descriptions in Russian.
'

# ── Batch Operations ────────────────────────────────────────────────────────
create_skill "batch-operations" '---
name: batch-operations
description: >
  Perform batch operations across multiple files. Use when the user asks
  to change, rename, update, migrate, or transform multiple files at once,
  or says "batch", "bulk", "across all files", "find and replace everywhere",
  "mass update", "apply to all".
---

# Batch Operations

Execute consistent changes across multiple files efficiently and safely.

## Process

1. **Scope** — identify all affected files.
   - Use `grep -r`, `find`, or `git ls-files` to build the file list.
   - Show the list to the user for confirmation before proceeding.

2. **Plan** — describe the exact transformation.
   - What pattern to match.
   - What to replace it with.
   - Any exceptions or conditions.

3. **Execute** — apply changes systematically.
   - Process files one by one or in small batches.
   - For each file: read -> transform -> write -> verify.

4. **Verify** — confirm correctness.
   - Run relevant tests / build after changes.
   - Show a summary: N files modified, M unchanged, K skipped.
   - Offer to show the diff for review.

## Safety Rules
- Always create a list of affected files BEFORE making changes.
- If > 20 files: ask for explicit confirmation.
- Never modify generated files, lock files, or binary files.
- If a transformation fails on one file, report it and continue with the rest.
- Provide a way to revert: `git stash` or `git checkout -- .` if in a repo.
'

echo ""

# ============================================================================
#  5. TECH STACK SKILLS
# ============================================================================
echo -e "${CYAN}--- Tech Stack Skills ---${NC}"

# ── Godot ────────────────────────────────────────────────────────────────────
create_skill "godot" '---
name: godot
description: >
  Godot Engine game development. Use when working with Godot, GDScript,
  C# in Godot, scenes, nodes, signals, physics, animation, or mentions
  "Godot", "GDScript", "gdscript", "scene tree", "node", "signal",
  "autoload", "export", "Godot 4".
---

# Godot Engine

Assist with Godot 4 game development using GDScript and C#.

## Scene & Node Architecture
- Everything is a Node. Scenes are reusable trees of nodes.
- Prefer composition over deep inheritance. Use `extends` sparingly.
- Scene root naming: match the scene file name.
- Use `@export` to expose properties to the Inspector — enables data-driven design.
- Pick the right base: `Node2D` for 2D, `Node3D` for 3D, plain `Node` only for logic.

## GDScript Patterns
```gdscript
# Typed GDScript — always annotate types in Godot 4
var health: int = 100
@export var speed: float = 200.0

# Signal declaration
signal died
signal health_changed(new_value: int)

func take_damage(amount: int) -> void:
    health -= amount
    health_changed.emit(health)
    if health <= 0:
        died.emit()
```

## Signals
- Prefer signals over direct node references for decoupling.
- Connect in `_ready()` or via the editor — not in `_process()`.
- Use typed signals: `signal foo(value: int)`.
- `call_deferred()` when modifying the scene tree from within a signal callback.

## Autoloads (Singletons)
- Use for global state: game settings, audio manager, save system.
- Keep autoloads small — not a dumping ground for everything.
- Access directly by autoload name: `GameManager.do_something()`.

## Physics
- `CharacterBody2D`/`3D` + `move_and_slide()` for player characters.
- `RigidBody` for physics-driven objects.
- Collision layers: plan your layer matrix early and document it.
- Use `_physics_process(delta)` for movement, never `_process()`.

## Performance
- Cache node references in `_ready()` — never call `get_node()` in hot loops.
- `MultiMeshInstance3D` for many identical objects.
- `VisibleOnScreenNotifier` to pause AI/animations when off-screen.
- `@tool` scripts for editor-time computation; avoid heavy `_process()` in tools.

## C# in Godot 4
- `[Export]` attribute instead of `@export`.
- Signals: declare with `[Signal]` delegate, emit via `EmitSignal(SignalName.Foo)`.
- Use Godot lifecycle methods (`_Ready`, `_Process`) — avoid constructor logic.
- NuGet packages are supported; avoid heavy reflection-based libraries.

## Export & Platform
- Set `application/config/name` and version in Project Settings before first export.
- Test on target platform early — especially mobile (touch input, aspect ratio).
- Use `OS.get_name()` for platform-specific code paths.
- Always use Export -> Release for distribution builds.
'

# ── FFmpeg ───────────────────────────────────────────────────────────────────
create_skill "ffmpeg" '---
name: ffmpeg
description: >
  FFmpeg video and audio processing. Use when the user works with video,
  audio, transcoding, encoding, filters, streaming, or mentions "ffmpeg",
  "transcode", "encode", "video convert", "extract audio", "filter graph",
  "HLS", "RTMP", "mux", "demux", "codec".
---

# FFmpeg

Assist with FFmpeg commands for video and audio processing.

## Core Concepts
- Container (mp4, mkv, mov) is separate from Codec (H.264, H.265, VP9, AAC).
- `-c copy` = remux without re-encoding (fast, no quality loss).
- `-c:v` = video codec, `-c:a` = audio codec.
- `-crf` = quality control (lower = better; H.264: 18-28, H.265: 24-28).
- `-preset` = speed vs compression (slow/medium/fast/veryfast).

## Common Operations

### Convert / Re-encode
```bash
# H.264 MP4, good quality
ffmpeg -i input.mov -c:v libx264 -crf 22 -preset medium -c:a aac -b:a 192k output.mp4

# H.265 (smaller file, slower encode)
ffmpeg -i input.mp4 -c:v libx265 -crf 28 -preset slow -c:a copy output.mp4

# WebM for web
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus output.webm

# AV1 (best compression, slow)
ffmpeg -i input.mp4 -c:v libaom-av1 -crf 35 -b:v 0 -c:a libopus output.mp4
```

### Trim / Cut (no re-encode)
```bash
# Put -ss BEFORE -i for fast keyframe seek
ffmpeg -ss 00:01:30 -to 00:02:45 -i input.mp4 -c copy output.mp4
```

### Extract Audio
```bash
ffmpeg -i input.mp4 -vn -c:a copy output.aac
ffmpeg -i input.mp4 -vn -c:a libmp3lame -q:a 2 output.mp3
ffmpeg -i input.mp4 -vn -c:a flac output.flac
```

### Scale / Resize
```bash
# Scale to 1080p, preserve aspect ratio
ffmpeg -i input.mp4 -vf "scale=-2:1080" -c:v libx264 -crf 22 output.mp4

# Scale + letterbox to exact 1920x1080
ffmpeg -i input.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" output.mp4
```

### Concatenate
```bash
# Create filelist.txt with entries like: file 'part1.mp4'
ffmpeg -f concat -safe 0 -i filelist.txt -c copy output.mp4
```

### Extract Frames
```bash
ffmpeg -i input.mp4 -vf "fps=1" frames/frame_%04d.png        # 1 frame per second
ffmpeg -ss 00:00:05 -i input.mp4 -frames:v 1 screenshot.png  # single frame
```

### High-Quality GIF
```bash
ffmpeg -i input.mp4 -vf "fps=15,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" output.gif
```

## Filter Graphs
```bash
# Multiple simple filters
ffmpeg -i input.mp4 -vf "scale=1280:720,fps=30" output.mp4

# Complex filter: overlay logo on video
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "[0:v][1:v]overlay=10:10" output.mp4

# Stack two videos side by side
ffmpeg -i left.mp4 -i right.mp4 \
  -filter_complex "[0:v][1:v]hstack" output.mp4
```

## HLS Streaming
```bash
ffmpeg -i input.mp4 -c:v libx264 -crf 22 \
  -hls_time 6 -hls_playlist_type vod \
  -hls_segment_filename "segment_%03d.ts" playlist.m3u8
```

## Batch Processing
```bash
for f in *.mov; do
    ffmpeg -i "$f" -c:v libx264 -crf 22 -c:a aac "${f%.mov}.mp4"
done
```

## Debugging
- `ffprobe input.mp4` — inspect streams, codecs, duration, bitrate.
- `ffmpeg -i input.mp4` — quick info (stderr).
- `-v verbose` for detailed encoding logs.
- `-progress pipe:1` for machine-readable progress output.
'

# ── C++ & Computer Graphics ──────────────────────────────────────────────────
create_skill "cpp-graphics" '---
name: cpp-graphics
description: >
  C++ and computer graphics programming. Use when working with C++, Vulkan,
  OpenGL, ray tracing, path tracing, shaders, GLSL, HLSL, or mentions
  "Vulkan", "ray tracing", "path tracing", "shader", "GLSL", "HLSL",
  "BVH", "graphics programming", "rasterization", "PBR", "BRDF",
  "C++ graphics", "compute shader".
---

# C++ & Computer Graphics

Assist with modern C++ and GPU graphics programming: Vulkan, shaders, ray tracing.

## Modern C++ (C++17/20)

### Resource Management
- RAII for all GPU handles — wrap VkBuffer, VkImage etc. in structs with destructors.
- Prefer `std::unique_ptr` / `std::shared_ptr` over raw `new`/`delete`.
- Use `[[nodiscard]]` on functions returning error codes or handles.
- `std::span<T>` for non-owning array views (C++20). Avoid raw pointer + size pairs.

### Performance Patterns
- Avoid `virtual` dispatch in hot paths — prefer templates or `std::variant`.
- Data-oriented design: structure of arrays (SoA) over array of structs (AoS) for cache efficiency.
- Use `alignas(16)` or `alignas(64)` for SIMD-friendly data.
- Profile before optimizing: `perf`, Intel VTune, NVIDIA Nsight.

## Vulkan

### Initialization Order
1. VkInstance -> VkPhysicalDevice -> VkDevice -> VkQueue
2. VkSurface -> VkSwapchain -> VkImageViews
3. VkRenderPass -> VkFramebuffer (or dynamic rendering in 1.3+)
4. VkDescriptorSetLayout -> VkPipelineLayout -> VkPipeline
5. VkCommandPool -> VkCommandBuffer
6. VkSemaphore / VkFence for frame synchronization

### RAII Pattern
```cpp
struct Buffer {
    VkDevice       device     = VK_NULL_HANDLE;
    VkBuffer       buffer     = VK_NULL_HANDLE;
    VmaAllocation  allocation = nullptr;

    Buffer() = default;
    Buffer(const Buffer&) = delete;
    Buffer(Buffer&& o) noexcept
        : device(o.device), buffer(o.buffer), allocation(o.allocation)
    { o.buffer = VK_NULL_HANDLE; }

    ~Buffer() {
        if (buffer != VK_NULL_HANDLE)
            vmaDestroyBuffer(g_allocator, buffer, allocation);
    }
};
```

### Validation Layers
```cpp
#ifdef NDEBUG
constexpr bool kEnableValidation = false;
#else
constexpr bool kEnableValidation = true;
#endif
// Always enable in debug. Never ship with validation on.
```

### Synchronization
- Use pipeline barriers for image layout transitions — stage and access masks must be correct.
- Prefer timeline semaphores (Vulkan 1.2+) over binary semaphores for complex multi-queue work.
- `VK_PIPELINE_STAGE_2_*` flags (synchronization2 extension) are cleaner — prefer them.
- Frame-in-flight pattern: N command buffers + N sets of semaphores (typically N=2 or 3).

## GLSL Shaders

### Vertex Shader
```glsl
#version 460

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inTexCoord;

layout(set = 0, binding = 0) uniform CameraUBO {
    mat4 view;
    mat4 proj;
    vec3 cameraPos;
} camera;

layout(push_constant) uniform PushConstants {
    mat4 model;
} pc;

layout(location = 0) out vec3 outWorldPos;
layout(location = 1) out vec3 outNormal;
layout(location = 2) out vec2 outTexCoord;

void main() {
    vec4 worldPos = pc.model * vec4(inPosition, 1.0);
    outWorldPos   = worldPos.xyz;
    outNormal     = mat3(transpose(inverse(pc.model))) * inNormal;
    outTexCoord   = inTexCoord;
    gl_Position   = camera.proj * camera.view * worldPos;
}
```

### Numeric Precision
- Use `highp` for positions and normals; `mediump` only for color output.
- Avoid catastrophic cancellation when a is approximately equal to b — reformulate.
- Clamp NaN-prone operations: `max(dot(n, l), 0.0)` not `dot(n, l)`.

## Ray Tracing & Path Tracing

### Core Data Structures
```cpp
struct Ray {
    glm::vec3 origin;
    glm::vec3 direction;  // normalized
    float tMin = 1e-4f;   // avoid self-intersection
    float tMax = 1e30f;
};

struct HitRecord {
    glm::vec3 point;
    glm::vec3 normal;     // always outward-facing after setFaceNormal
    float     t;
    bool      frontFace;
    Material* material = nullptr;

    void setFaceNormal(const Ray& r, const glm::vec3& outwardNormal) {
        frontFace = glm::dot(r.direction, outwardNormal) < 0.0f;
        normal    = frontFace ? outwardNormal : -outwardNormal;
    }
};
```

### BVH (Bounding Volume Hierarchy)
- Build: sort primitives by centroid along the longest AABB axis, split at median.
  SAH (Surface Area Heuristic) gives better quality at the cost of build time.
- Traverse: test both children when ray hits parent AABB; visit nearest child first.
- Leaf size: 1-4 primitives per leaf depending on intersection cost.
- Storage: flatten tree to array in DFS order for cache-friendly traversal.

### Path Tracing Estimator
```
L(x, wo) = Le(x, wo) + integral[ fr(x, wi, wo) * Li(x, wi) * |cos(theta_i)| ] dwi

Monte Carlo estimate:
L ~= (1/N) * sum[ fr(wi) * Li(wi) * |cos(theta_i)| / pdf(wi) ]
```
- Russian Roulette: terminate paths with probability (1 - throughput). Divide surviving paths by survival probability.
- Next Event Estimation (NEE): explicitly sample lights + combine with BRDF sample via MIS.
- Importance sampling: sample BRDF lobe, not uniform hemisphere. For GGX use VNDF sampling.

### PBR / BRDF
- Lambertian diffuse: `fr = albedo / PI`
- GGX specular: `fr = (D * G * F) / (4 * NdotL * NdotV)`
  - D = GGX/Trowbridge-Reitz normal distribution function
  - G = Smith correlated masking-shadowing
  - F = Schlick Fresnel approximation
- Energy conservation: `diffuse_weight = (1 - metallic) * (1 - F)`.
- Use the metallic-roughness workflow (UE4/glTF standard).

## Math Utilities
```cpp
// Orthonormal basis from a normal vector (Pixar ONB, numerically stable)
void buildONB(const glm::vec3& n, glm::vec3& t, glm::vec3& b) {
    float sign = std::copysign(1.0f, n.z);
    float a    = -1.0f / (sign + n.z);
    float c    = n.x * n.y * a;
    t = glm::vec3(1.0f + sign * n.x * n.x * a,  sign * c,        -sign * n.x);
    b = glm::vec3(c,                              sign + n.y*n.y*a, -n.y);
}

// Cosine-weighted hemisphere sample (Malley method)
glm::vec3 cosineSampleHemisphere(float u1, float u2) {
    float r   = std::sqrt(u1);
    float phi = 2.0f * glm::pi<float>() * u2;
    return { r * std::cos(phi), r * std::sin(phi), std::sqrt(1.0f - u1) };
}

// Low-discrepancy sequence: Halton
float halton(int index, int base) {
    float result = 0.0f, f = 1.0f;
    while (index > 0) { f /= base; result += f * (index % base); index /= base; }
    return result;
}
```
'

echo ""

# ============================================================================
#  6. SYMLINK FOR OPENCODE
# ============================================================================
echo -e "${CYAN}--- Linking for OpenCode ---${NC}"

for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    target="$OPENCODE_DIR/$skill_name"

    if [ -L "$target" ]; then
        rm "$target"
    elif [ -d "$target" ]; then
        rm -rf "$target"
    fi

    if ln -s "$skill_dir" "$target" 2>/dev/null; then
        :
    else
        cp -r "$skill_dir" "$target"
    fi
done
ok "Linked $(ls -1d "$SKILLS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ') skills -> $OPENCODE_DIR"
echo ""

# ============================================================================
#  SUMMARY
# ============================================================================
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo "Installed skills:"
echo ""

printf "%-30s %s\n" "SKILL" "SOURCE"
printf "%-30s %s\n" "-----" "------"

# Official
for s in skill-creator frontend-design webapp-testing mcp-builder internal-comms doc-coauthoring keybindings-help simplify; do
    [ -d "$SKILLS_DIR/$s" ] && printf "%-30s %s\n" "$s" "anthropics/skills"
done

# Planning
[ -d "$SKILLS_DIR/planning-with-files" ] && printf "%-30s %s\n" "planning-with-files" "OthmanAdi/planning-with-files"

# Web quality
for s in web-quality-audit performance accessibility core-web-vitals best-practices seo; do
    [ -d "$SKILLS_DIR/$s" ] && printf "%-30s %s\n" "$s" "addyosmani/web-quality-skills"
done

# Custom workflow
for s in code-review debug-workflow simplify-refactor security-audit docker-helper sql-helper github-actions react-typescript changelog-generator batch-operations; do
    [ -d "$SKILLS_DIR/$s" ] && printf "%-30s %s\n" "$s" "custom"
done

# Tech stack
for s in godot ffmpeg cpp-graphics; do
    [ -d "$SKILLS_DIR/$s" ] && printf "%-30s %s\n" "$s" "custom"
done

echo ""
echo "Paths:"
echo "  Claude Code: $SKILLS_DIR"
echo "  OpenCode:    $OPENCODE_DIR"
echo ""
echo "Note: anthropic-skills:* (pdf, xlsx, pptx, docx, schedule) are built-in"
echo "      to Claude Code and do not require manual installation."
echo ""
echo "To verify in Claude Code:  /skills"
echo "To verify in OpenCode:     ask 'list available skills'"
echo ""
echo "To uninstall: rm -rf $SKILLS_DIR $OPENCODE_DIR"
