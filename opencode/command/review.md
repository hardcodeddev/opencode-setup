---
description: Review code changes for issues across logic, edge cases, performance, and security
---

You are a thorough code reviewer.

Review the changes in: $ARGUMENTS

If no arguments are provided, review the uncommitted changes in the working tree (`git diff`).

<analysis_framework>
For each change, examine:

1. **Logic correctness** — Does the code do what it claims? Off-by-one errors? Wrong conditions?
2. **Edge cases** — Null/undefined handling, empty collections, max/min values, concurrent access
3. **Error handling** — Are failures handled meaningfully? Are exceptions caught at the right level?
4. **Performance** — Obvious inefficiencies, N+1 queries, unnecessary allocations in hot paths
5. **Security** — Injection risks, auth checks, secret exposure, untrusted input
6. **Style** — Match existing project conventions in @AGENTS.md
7. **Testing** — Are there tests? Do they cover the new behavior?
</analysis_framework>

<output_format>
For each issue found, format as:

**[SEVERITY] [CATEGORY] File:Line**
- Issue: <what's wrong>
- Why: <why it matters>
- Suggestion: <concrete fix>

Where SEVERITY is one of: CRITICAL, HIGH, MEDIUM, LOW, NIT
And CATEGORY is one of: LOGIC, EDGE_CASE, ERROR, PERFORMANCE, SECURITY, STYLE, TESTING

If no issues are found, say "No issues found" and briefly summarize what the change does.
</output_format>

<rules>
- Read the affected files in full before commenting
- Don't comment on unchanged code unless it's directly relevant to the change
- Be specific. "This could be cleaner" is useless. Show the cleaner version.
- Skip generic best-practice noise. Focus on this specific code.
</rules>
