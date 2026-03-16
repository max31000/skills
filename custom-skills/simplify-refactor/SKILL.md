---
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
