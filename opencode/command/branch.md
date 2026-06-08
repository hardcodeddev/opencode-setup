---
description: Create a feature branch from main and switch to it — never commits to main directly
---

You are helping the developer start work on a new feature or fix. Your job is to create a properly-named feature branch and push it to origin so the developer can track it remotely.

## Rules (non-negotiable)
- NEVER push directly to `main` or `master`
- NEVER work on `main` or `master` directly
- NEVER merge a pull request — that is the developer's job
- Always create a branch BEFORE making any code changes

## Steps

1. Read `AGENTS.md` (or `AGENTS.generic.md`) if it exists to find the project's branch naming convention.
2. Ask the developer: "What are you working on?" if `$ARGUMENTS` is empty. If `$ARGUMENTS` is provided, use it as the feature description.
3. Derive a branch name from the description:
   - Format: `feat/<slug>`, `fix/<slug>`, `chore/<slug>`, `docs/<slug>`, or `refactor/<slug>`
   - Slug: lowercase, hyphens only, max 40 chars, no ticket numbers unless provided
   - Examples: `feat/user-auth-jwt`, `fix/null-pointer-on-login`, `chore/upgrade-deps`
4. Run: `git fetch origin main`
5. Run: `git checkout -b <branch-name> origin/main`
6. Run: `git push -u origin <branch-name>`
7. Confirm the branch is active and clean with `git status`
8. Report back: branch name, base commit, and a one-line description of what will be built

## Output
```
Branch created: <branch-name>
Base: <short-sha> on origin/main
Ready for: <what you're about to build>
```
