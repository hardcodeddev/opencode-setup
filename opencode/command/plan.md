---
description: Create a detailed implementation plan before any code is written
---

You are planning an implementation. DO NOT WRITE CODE in this command. Output a plan only.

Task: $ARGUMENTS

<process>
1. **Understand**. Read relevant files. Identify the affected areas of the codebase. Look at @AGENTS.md for conventions.

2. **Clarify**. List any ambiguities or assumptions before proceeding. If a critical detail is unclear, STOP and ask.

3. **Decompose**. Break the task into 3-8 concrete steps. Each step should be small enough to commit individually.

4. **Identify risks**. What could break? What's the rollback strategy?

5. **Estimate**. Rough complexity per step (S/M/L) and rough total time.
</process>

<output_format>

## Goal
<one-sentence description of what we're building>

## Affected files
- `path/to/file1.ext` — <what changes>
- `path/to/file2.ext` — <what changes>

## Open questions
<assumptions you're making, or things you need clarified>

## Steps
1. **<Step name>** (S/M/L)
   - <What to do>
   - <Why>
   - <Validation: how we know it worked>

2. **<Step name>** (S/M/L)
   ...

## Risks
- <Risk 1>: <Mitigation>
- <Risk 2>: <Mitigation>

## Rollback strategy
<How to revert if things go wrong>

## Total estimate
<Time + complexity>

</output_format>

<rules>
- DO NOT write any code. Just plan.
- Be honest about what you don't know.
- If the task is too vague to plan, ask 1-3 specific clarifying questions instead.
- If the task is huge (>1 day estimated), suggest breaking it into smaller separately-planned chunks.
</rules>
