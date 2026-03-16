---
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
