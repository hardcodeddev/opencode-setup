# Skill: Code Review Lens

Apply this skill when reviewing a diff, PR, or file. Use this structured lens to catch real issues without generating noise.

## Review order (do this in sequence)

### 1. Understand intent first
- What is this change trying to do?
- Read the PR description or commit message before looking at the code
- If there's no description, infer from the code — then question if your inference is right

### 2. Correctness (highest priority)
- Does the code do what it says?
- Are there off-by-one errors, wrong comparison operators, inverted conditions?
- Are error paths handled, or silently swallowed?
- Is the return value of every called function checked if it can fail?
- Are concurrent accesses to shared state safe?

### 3. Edge cases
- What happens with empty input (null, empty string, empty array, zero)?
- What happens at the boundaries (max value, min value, single element)?
- What if the external dependency is unavailable?
- What if the operation is retried — is it idempotent?

### 4. Security (see security-mindset.md)
- Any new user-controlled input? Is it validated and sanitized?
- Any new database queries? Parameterized?
- Any new authentication-sensitive code? Is access checked?
- Any new dependencies? Are they trusted?

### 5. Maintainability
- Will a developer who hasn't seen this code understand it in 6 months?
- Are names intent-revealing?
- Is there duplication that should be extracted?
- Are there magic numbers/strings that should be constants?

### 6. Tests
- Does the change have tests?
- Do the tests test behavior or just implementation details?
- Are failure paths tested, not just happy path?

## Severity classification
- **MUST FIX**: correctness bug, security vulnerability, data loss risk
- **SHOULD FIX**: likely bug in edge case, missing error handling, unclear ownership
- **CONSIDER**: maintainability improvement, potential performance concern, style inconsistency
- **NIT**: cosmetic, minor style, totally optional

## What NOT to comment on
- Code that wasn't changed in this diff (unless it's directly interacted with)
- Personal preferences not backed by the project's style guide
- "I would have done it differently" without a concrete reason
- Speculation about future requirements

## Output format
```
File: <path>
Lines: <range>
Severity: MUST FIX / SHOULD FIX / CONSIDER / NIT
Category: correctness / edge-case / security / maintainability / tests
Issue: <one sentence>
Why it matters: <consequence>
Suggested direction: <concrete, brief>
```
