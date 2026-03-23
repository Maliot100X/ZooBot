---
name: zoobot-conventions
description: Development conventions and patterns for ZooBot. TypeScript project with conventional commits.
---

# Zoobot Conventions

> Generated from [Maliot100X/ZooBot](https://github.com/Maliot100X/ZooBot) on 2026-03-23

## Overview

This skill teaches Claude the development patterns and conventions used in ZooBot.

## Tech Stack

- **Primary Language**: TypeScript
- **Architecture**: type-based module organization
- **Test Location**: separate

## When to Use This Skill

Activate this skill when:
- Making changes to this repository
- Adding new features following established patterns
- Writing tests that match project conventions
- Creating commits with proper message format

## Commit Conventions

Follow these commit message conventions based on 8 analyzed commits.

### Commit Style: Conventional Commits

### Prefixes Used

- `fix`
- `feat`
- `chore`
- `refactor`
- `docs`

### Message Guidelines

- Average message length: ~56 characters
- Keep first line concise and descriptive
- Use imperative mood ("Add feature" not "Added feature")


*Commit message example*

```text
docs(agents): move setup and system prompt config to workspace-level AGENTS.md (#253)
```

*Commit message example*

```text
refactor(telegram): migrate from node-telegram-bot-api to grammY (#248)
```

*Commit message example*

```text
fix(api): resolve agent routing at enqueue time (#247)
```

*Commit message example*

```text
chore: update readme
```

*Commit message example*

```text
feat(office): redesign the live office workspace (#212)
```

*Commit message example*

```text
Initial ZooBot commit - Open Source AI Agent Framework with Groq support
```

*Commit message example*

```text
fix(telegram): fix watchdog timer bug that prevented polling restart (#246)
```

*Commit message example*

```text
chore: add bin entry to package.json, update README and office screenshot
```

## Architecture

### Project Structure: Monorepo

This project uses **type-based** module organization.

### Configuration Files

- `.github/workflows/release.yml`
- `package.json`
- `packages/channels/package.json`
- `packages/channels/tsconfig.json`
- `packages/cli/package.json`
- `packages/cli/tsconfig.json`
- `packages/core/package.json`
- `packages/core/tsconfig.json`
- `packages/main/package.json`
- `packages/main/tsconfig.json`
- `packages/server/package.json`
- `packages/server/tsconfig.json`
- `packages/teams/package.json`
- `packages/teams/tsconfig.json`
- `packages/visualizer/package.json`
- `packages/visualizer/tsconfig.json`
- `tinyoffice/package.json`
- `tinyoffice/tsconfig.json`
- `tsconfig.json`

### Guidelines

- Group code by type (components, services, utils)
- Keep related functionality in the same type folder
- Avoid circular dependencies between type folders

## Code Style

### Language: TypeScript

### Naming Conventions

| Element | Convention |
|---------|------------|
| Files | camelCase |
| Functions | camelCase |
| Classes | PascalCase |
| Constants | SCREAMING_SNAKE_CASE |

### Import Style: Relative Imports

### Export Style: Named Exports


*Preferred import style*

```typescript
// Use relative imports
import { Button } from '../components/Button'
import { useAuth } from './hooks/useAuth'
```

*Preferred export style*

```typescript
// Use named exports
export function calculateTotal() { ... }
export const TAX_RATE = 0.1
export interface Order { ... }
```

## Error Handling

### Error Handling Style: Try-Catch Blocks

A **global error handler** catches unhandled errors.


*Standard error handling pattern*

```typescript
try {
  const result = await riskyOperation()
  return result
} catch (error) {
  console.error('Operation failed:', error)
  throw new Error('User-friendly message')
}
```

## Common Workflows

These workflows were detected from analyzing commit patterns.

### Database Migration

Database schema changes with migration files

**Frequency**: ~2 times per month

**Steps**:
1. Create migration file
2. Update schema definitions
3. Generate/update types

**Files typically involved**:
- `**/types.ts`

**Example commit sequence**:
```
refactor(queue): simplify schema and remove conversation state (#213)
feat(invoke): stream agent execution progress in real-time (#196)
refactor(cli): make tinyagi the primary CLI entrypoint (#234)
```

### Feature Development

Standard feature implementation workflow

**Frequency**: ~17 times per month

**Steps**:
1. Add feature implementation
2. Add tests for feature
3. Update documentation

**Files typically involved**:
- `packages/main/src/*`
- `packages/server/src/*`
- `packages/server/src/routes/*`
- `**/api/**`

**Example commit sequence**:
```
feat: add chat rooms and projects to tinyoffice (#199)
fix(telegram): prevent polling from stalling after network reconnect (#200)
feat(office): add organization chart visualization page (#201)
```

### Refactoring

Code refactoring and cleanup workflow

**Frequency**: ~6 times per month

**Steps**:
1. Ensure tests pass before refactor
2. Refactor code structure
3. Verify tests still pass

**Files typically involved**:
- `src/**/*`

**Example commit sequence**:
```
refactor(ui): refactor agent and task components into modules (#229)
fix(heartbeat): persist per-agent enabled and interval settings to heartbeat overrides (#230)
chore: bump version to 0.0.14 and add release notes
```


## Best Practices

Based on analysis of the codebase, follow these practices:

### Do

- Use conventional commit format (feat:, fix:, etc.)
- Use camelCase for file names
- Prefer named exports

### Don't

- Don't write vague commit messages
- Don't deviate from established patterns without discussion

---

*This skill was auto-generated by [ECC Tools](https://ecc.tools). Review and customize as needed for your team.*
