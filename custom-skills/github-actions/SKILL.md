---
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
