# AGENTS.md — Generic Project Starter Template

> Drop this at the root of any repo as `AGENTS.md`. Fill in placeholders, trim irrelevant sections, add your own.

---

# AGENTS.md

This document is the source of truth for project conventions, architecture, and rules. Read it before making changes.

## How to work in this project

<rules>
1. **MUST** use Plan mode for any task touching more than one file.
2. **MUST** read existing code in the affected area before writing new code.
3. **MUST** match existing patterns and style.
4. **MUST NOT** introduce new dependencies without confirming first.
5. **MUST NOT** commit secrets, credentials, or API keys.
6. **SHOULD** prefer modifying existing files over creating new ones.
7. **SHOULD** ask clarifying questions when requirements are ambiguous.
8. **SHOULD** make commits small and focused.
</rules>

## Project overview

<project>
- **Name**: <project-name>
- **Purpose**: <one-sentence description>
- **Stage**: <prototype | active development | maintenance>
</project>

## Tech stack

<stack>
- **Language**: <e.g., TypeScript 5.4, Python 3.12, Go 1.22>
- **Framework**: <e.g., Next.js 15, FastAPI, Gin>
- **Database**: <e.g., PostgreSQL, MongoDB, none>
- **Testing**: <e.g., Vitest, pytest, go test>
- **Linting**: <e.g., ESLint + Prettier, ruff, golangci-lint>
- **Package manager**: <e.g., pnpm, uv, go mod>
</stack>

## Project structure

<structure>
Describe the high-level directory layout:

```
src/
  components/   # UI components
  lib/          # Shared utilities
  ...
tests/
  unit/
  integration/
```

Or just describe it in prose: "All source is under `src/`. Tests live next to the code they test as `*.test.ts`."
</structure>

## Code conventions

<conventions>
- **Naming**: <camelCase for variables and functions, PascalCase for types, kebab-case for files>
- **Imports**: <e.g., absolute imports from `~/`, no relative imports above one level>
- **Comments**: <only for *why*, not *what*. Code should be self-explanatory.>
- **Error handling**: <e.g., never swallow errors, always log or propagate>
- **Async**: <e.g., all I/O is async; never block the event loop>
</conventions>

## Build / Run / Test

<commands>
```bash
# Install dependencies
<install command, e.g., pnpm install>

# Run dev server
<dev command, e.g., pnpm dev>

# Run all tests
<test command, e.g., pnpm test>

# Lint and format
<lint command, e.g., pnpm lint>

# Build for production
<build command, e.g., pnpm build>
```
</commands>

## Testing protocols

<testing>
- **Coverage target**: <e.g., 80% line coverage, focused on business logic>
- **Test naming**: <e.g., describe("Component") > it("does X when Y")>
- **What to test**: behavior, not implementation
- **What NOT to test**: third-party libraries, framework internals
- **New features require new tests. Bug fixes require regression tests.**
</testing>

## Git workflow

<git>
- Branch naming: `<type>/<short-description>` (e.g., `feat/user-auth`, `fix/login-redirect`)
- Commit format: Conventional Commits — `<type>(<scope>): <description>`
- Squash on merge to main
- Never force-push to shared branches
</git>

## Security baseline

<security>
- All user input is untrusted. Validate at the boundary.
- Secrets via environment variables or secret manager. Never in source.
- No string interpolation into queries. Use parameterized queries / ORMs.
- Log security events but never log secrets.
</security>

## Glossary

<glossary>
<!-- Define project-specific terms -->
- **<Term>**: <Definition>
</glossary>

## Known quirks

<quirks>
<!-- Warnings about non-obvious things -->
- <e.g., "The auth module uses a custom token format, not standard JWT.">
</quirks>

## When in doubt

<fallback>
- Ask clarifying questions instead of guessing
- Show me the plan before destructive operations
- If you need a new dependency, ask first
- If something feels architecturally wrong, call it out
</fallback>
