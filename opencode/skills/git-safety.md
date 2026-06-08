# Skill: Git Safety

Apply this skill whenever performing any git operations. These rules protect the developer's repository from irreversible mistakes.

## Branch protection (absolute rules)
1. NEVER push to `main` or `master` — always work on a feature branch
2. NEVER merge a pull request — that decision belongs to the human developer
3. NEVER force-push (`--force`) to any shared branch (a branch that exists on `origin`)
4. NEVER amend or rebase published commits — create new commits instead
5. NEVER delete a remote branch without explicit developer confirmation
6. NEVER use `git push --no-verify` or `git commit --no-verify`

## Branch naming convention
```
<type>/<short-slug>
```
Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `ci`
Slug: lowercase, hyphens, max 40 chars
Examples: `feat/oauth-login`, `fix/memory-leak-on-close`, `chore/bump-go-1.22`

## Before every commit
1. Run `git diff` — read every changed line
2. Scan for secrets: API keys, passwords, tokens, private keys, `.env` contents
3. Check for unintended files: build artifacts, IDE configs, OS files, large binaries
4. Stage specific files — not `git add -A` blindly
5. Write a conventional commit message: `<type>(<scope>): <summary>`

## When something goes wrong
- Accidental commit to main → `git revert HEAD` and push, then move the change to a feature branch
- Merge conflict during rebase → explain the conflict to the developer, do NOT use `--skip`
- Diverged history → prefer `git pull --rebase` over merge commits on feature branches

## What to report after every git operation
```
Operation: <what was done>
Branch: <current branch>
Status: pushed to origin / pending push
Next step: <what the developer should do>
```
