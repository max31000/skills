---
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
