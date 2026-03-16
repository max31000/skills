---
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
