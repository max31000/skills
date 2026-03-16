---
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
