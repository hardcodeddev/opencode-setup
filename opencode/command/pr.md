---
description: Create a pull request for review — never merges it, that is the developer's decision
---

You are preparing a pull request for the developer to review. Your job is to summarize the changes clearly, write a useful PR description, and create the PR — then stop. You do NOT merge.

## Rules (non-negotiable)
- NEVER merge the pull request — that is solely the developer's decision
- NEVER approve the pull request
- NEVER enable auto-merge
- NEVER push to `main` or `master`
- If the branch has uncommitted changes, run `/commit` first

## Steps

1. Verify you are not on `main`/`master`: `git branch --show-current`
   - If on main, STOP: "Cannot create a PR from main. Run `/branch` then make your changes."

2. Ensure all changes are committed and pushed: `git status`
   - If dirty, prompt: "You have uncommitted changes. Run `/commit` first."

3. Gather PR context:
   - `git log origin/main..HEAD --oneline` — list commits in this branch
   - `git diff origin/main...HEAD --stat` — files changed
   - Read changed files to understand the scope

4. Build the PR description:
   ```markdown
   ## What changed
   <2-4 bullet points, plain language, what the user sees or what problem is solved>

   ## Why
   <1-2 sentences: the motivation or bug being fixed>

   ## How
   <brief technical summary only if non-obvious>

   ## Test plan
   - [ ] <specific thing to test manually>
   - [ ] <edge case to verify>
   - [ ] Existing tests pass

   ## Notes for reviewer
   <anything that needs extra attention, known trade-offs, out-of-scope items>
   ```

5. Create the PR using the git host's CLI or API (e.g., `gh pr create`):
   - Base branch: `main` (or as specified in `AGENTS.md`)
   - Title: conventional format — `feat: <summary>` or `fix: <summary>` (max 72 chars)
   - Set reviewers if specified in `$ARGUMENTS`

6. Report the PR URL and remind the developer it awaits their review.

## Output
```
PR created: <URL>
Title: <title>
Branch: <branch> → main
Commits: <N>
Status: AWAITING YOUR REVIEW — not merged
```
