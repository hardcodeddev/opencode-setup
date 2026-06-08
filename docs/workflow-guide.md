# Workflow Guide

How to actually use this setup day to day.

## The core loop

```
  ┌─────────────────────────────────────────┐
  │  cd into project                        │
  │  opencode                               │
  └────────────────┬────────────────────────┘
                   │
                   ▼
  ┌─────────────────────────────────────────┐
  │  Press Tab → Plan mode                  │
  │  Describe what you want                 │
  │  Review the plan                        │
  └────────────────┬────────────────────────┘
                   │
                   ▼
  ┌─────────────────────────────────────────┐
  │  Press Tab → Build mode                 │
  │  Watch the agent execute                │
  │  Approve or correct each step           │
  └────────────────┬────────────────────────┘
                   │
                   ▼
  ┌─────────────────────────────────────────┐
  │  Test & commit                          │
  │  Update AGENTS.md if you learned        │
  │  something new                          │
  └─────────────────────────────────────────┘
```

## Setting up a new project

The first time you use OpenCode in a project, spend 10 minutes on this:

1. **Copy an AGENTS.md template into the project root.**
   - For .NET: `templates/AGENTS.dotnet.md`
   - For anything else: `templates/AGENTS.generic.md`
2. **Fill in the placeholders.** Tech stack, conventions, glossary terms, anything project-specific.
3. **Add the local `.opencode/` directory** for project-specific commands and agents (optional, but useful).

This file is the single highest-ROI thing you can do. Every prompt that doesn't have to re-explain your project saves tokens and improves quality.

## Modes: when to use which

### Plan mode (Tab to enter)

Use when:
- The task touches more than one file
- You're not sure how to approach something
- You want a sanity check before committing to a direction
- The model might go off the rails (it will)

In Plan mode, the agent is read-only. It can read files, search, and think. It cannot edit, delete, or run anything destructive. Its job is to produce a step-by-step plan you approve.

### Build mode (Tab to exit Plan)

Use when:
- You've approved the plan
- The task is simple and unambiguous (one-file edit, rename, format)

In Build mode the agent can write, edit, and execute. Permission gates still ask before destructive operations.

### Rule of thumb

If you have to think for more than 5 seconds about whether to use Plan mode — use Plan mode. Local models drift; the plan-review-execute cycle catches it early.

## Effective prompting for local models

Local models (Qwen3-Coder, DeepSeek, etc.) are noticeably more sensitive to prompt quality than Claude. Things that help:

### Use XML structure

```
<task>Add rate limiting to the /api/auth/login endpoint</task>

<constraints>
- Use the existing Redis client at @src/lib/redis.ts
- Limit: 5 attempts per 15 minutes per IP
- Return 429 with Retry-After header
- Don't add new dependencies
</constraints>

<context>
- @src/routes/auth/login.ts (the endpoint)
- @src/middleware/rate-limit.ts (existing rate limit middleware to model after)
- @AGENTS.md
</context>
```

This format dramatically outperforms free-form prose with Qwen models.

### Load context upfront

`@path/to/file` references at the start of the prompt load files into context before the model thinks. Always cheaper than letting the model discover them via tool calls.

### Be explicit

Don't:
> Fix the bug in the auth flow

Do:
> The login endpoint at @src/routes/auth/login.ts returns 200 even when the password is wrong. Reproduce with `curl -X POST localhost:3000/api/auth/login -d '{"email":"test@test.com","password":"wrong"}'`. Find and fix the bug.

### Constrain scope

Don't:
> Improve the codebase

Do:
> In @src/components/UserCard.tsx, extract the avatar logic into a separate component. Don't change anything else.

### Smaller tasks

Local models do better on 5-15 minute chunks than 1-hour epics. Decompose.

## Context management

### Watch your token usage

Type `/tokens` to see context usage. When you're at 60-70% of capacity, performance starts degrading visibly.

### Compact regularly

`/compact` condenses the conversation while preserving the important state. Use it:
- Before starting a new sub-task within the same session
- When responses start getting weird or forgetful
- After completing a major step

### Start fresh when needed

`/clear` wipes context entirely. Use it when:
- Switching to an unrelated task
- The conversation has degraded past saving
- You want to verify a fix in a clean session

## Working with the file system

OpenCode can read, write, and execute on the **client machine**, not the server. Your code, your files, your terminal.

- File reads are cheap. Use them liberally.
- File writes need approval by default. Don't approve blindly.
- `git diff` before approving multi-file changes.
- `git stash` is your friend. So is `git reset --hard`.

## Commit hygiene

Commit before any multi-file change. This:
1. Gives you a clean rollback point
2. Lets you see exactly what the agent changed
3. Makes the next session start from a known state

A common pattern:
```bash
git add -A && git commit -m "wip: pre-agent checkpoint"
opencode  # do the agent task
git diff  # review what changed
git add -A && git commit -m "feat: <what got done>"
```

If the agent messed it up: `git reset --hard HEAD~1` and try a different prompt.

## When to escalate to Claude

Local models on a single 8GB-16GB GPU handle ~70-80% of daily work well. Save Claude (claude.ai or Claude Code) for:

- Multi-file refactors spanning 10+ files
- Architectural design conversations
- Subtle debugging requiring deep reasoning across a large codebase
- Working with novel frameworks/libraries the model wasn't trained on
- Tasks where you've iterated 5+ times with the local model and it's still not getting it

Hybrid is the move. Use local for 80-90%; escalate for the gnarly stuff.

## Improving over time

Every time the agent does something dumb, ask yourself:
> What could I have written in AGENTS.md (or a command, or a subagent) to prevent this?

Add it. Save. Next time benefits.

After 2-3 weeks of this loop, you'll have a setup that's distinctly yours. The agent will start to feel like it actually knows your project.
