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
6. **MUST NOT** push to `main` or `master` — always use a feature branch.
7. **MUST NOT** merge pull requests — that is the developer's decision.
8. **MUST NOT** force-push to any branch that exists on `origin`.
9. **SHOULD** prefer modifying existing files over creating new ones.
10. **SHOULD** ask clarifying questions when requirements are ambiguous.
11. **SHOULD** make commits small and focused (one logical change per commit).
12. **SHOULD** write or update tests for every behavioral change.
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

### Hermetic integration tests
Integration tests MUST be hermetic — fully self-contained, no real external dependencies:
- No real database calls — use in-memory DB or Testcontainers
- No real HTTP calls — use an HTTP interceptor (msw, WireMock, httptest.Server)
- No real file system paths outside a temp directory
- No real-world time — inject a fixed clock (`2024-01-15T00:00:00Z`)
- No shared state between tests — each test sets up and tears down its own data
- Cleanup runs unconditionally (in `afterEach`/`defer`/`finally`), even on failure
- Annotate each integration test file: `// Hermetic: yes // Mocked: [list deps]`
</testing>

## Git workflow

<git>
### Branch protection (non-negotiable)
- **NEVER push to `main` or `master`** — all work happens on feature branches
- **NEVER merge a pull request** — PRs are created for developer review, not auto-merged
- **NEVER force-push** (`--force`) to any shared branch
- **NEVER use `--no-verify`** to skip commit hooks
- **NEVER commit secrets** — scan diff for API keys, tokens, passwords before every commit

### Branch naming
Format: `<type>/<short-description>`
Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `ci`
Examples: `feat/user-auth`, `fix/login-redirect`, `chore/upgrade-deps`

### Commit format: Conventional Commits
```
<type>(<scope>): <summary, imperative, max 72 chars>

<body: why this change was needed — omit if self-evident>

<footer: BREAKING CHANGE: ..., Closes #N>
```

### Workflow for every change
1. `git fetch origin main`
2. `git checkout -b <type>/<slug> origin/main`
3. Make changes, run tests
4. `git push -u origin <branch-name>`
5. Create PR for developer review — do not merge

### PR creation
- Title: `<type>: <summary>` (max 72 chars)
- Body: what changed, why, how to test manually
- Base branch: `main`
- After creating: report the PR URL and stop — the developer merges
</git>

## Security baseline

<security>
- All user input is untrusted. Validate at the boundary (length, type, range, format).
- Secrets via environment variables or secret manager. Never in source. Never in git.
- No string interpolation into queries. Use parameterized queries / ORMs.
- Log security events but never log: auth tokens, session IDs, passwords, PII, API keys.
- Authentication AND authorization on every protected route — never assume it was done elsewhere.
- Cryptography: `bcrypt`/`argon2` for passwords; `crypto.randomBytes`/`secrets` module for tokens; never MD5/SHA1 for security.
- NEVER disable TLS certificate verification (`verify=False`, `rejectUnauthorized: false`).
- File uploads: validate MIME type, extension allowlist, enforce size limit.
- HTML output: always escape user content. Never use `dangerouslySetInnerHTML` / `innerHTML` with user data.
- Before every commit: scan diff for hardcoded credentials, `.env` files, private keys.
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
