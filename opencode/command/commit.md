---
description: Stage and commit changes with a conventional commit message — never to main
---

You are creating an atomic, well-described commit. Your job is to group logically related changes, write a clear conventional commit message, and push to the current feature branch.

## Rules (non-negotiable)
- NEVER commit to `main` or `master` — abort and run `/branch` first if on main
- NEVER push to `main` or `master`
- NEVER use `--no-verify` to skip hooks
- NEVER bundle unrelated changes in one commit
- Keep commits atomic: one logical change per commit

## Steps

1. Check current branch: `git branch --show-current`
   - If it is `main` or `master`, STOP and say: "I will not commit to main. Run `/branch` to create a feature branch first."

2. Run `git diff` and `git diff --cached` to see all changes.

3. Analyze the diff — group changes into logical units if needed.

4. Stage appropriate files:
   - Stage specific files, not `git add -A` or `git add .` blindly
   - Never stage: `.env`, secrets, credentials, large binaries, `*.log`, or anything in `.gitignore`
   - If you see anything suspicious (API keys, passwords, private keys) in the diff — STOP and warn the developer before proceeding

5. Write a conventional commit message:
   ```
   <type>(<scope>): <short summary under 72 chars>

   <optional body: why this change was needed, what problem it solves>
   <wrap at 72 chars>

   <optional footer: BREAKING CHANGE, closes #issue, co-authored-by>
   ```
   Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`

6. Run: `git commit -m "<message>"`

7. Run: `git push -u origin <branch-name>`

8. Report: commit sha, files changed, message summary

## Output
```
Committed: <short-sha>
Branch: <branch-name> → pushed to origin
Files: <N> changed, <insertions>(+), <deletions>(-)
Message: <type>(<scope>): <summary>
```
