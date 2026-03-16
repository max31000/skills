---
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
