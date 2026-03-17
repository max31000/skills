# Bootstrap Architecture

This repository is a bootstrap and synchronization source of truth for AI coding environments.

## Layers

1. `manifest/` declares desired state.
2. `assets/` stores repository-owned config content and local additions.
3. `custom-skills/` stores first-class local context.
4. `scripts/` executes installation, rendering, synchronization, and verification.

Top-level `bootstrap.sh` / `bootstrap.ps1` are compatibility wrappers that call the real scripts under `scripts/` without requiring executable file permissions on checkout.

## Managed Context

The repository owns AI-agent-specific context only:

- settings/config for Claude Code and OpenCode
- skills
- commands
- agents
- MCP definitions
- plugin declarations and backends
- direct CLI/runtime dependencies needed to render and install that context

## Targets

- Claude Code
- OpenCode

The shared source model allows target-specific rendering where formats differ.
