# Skill: Test-First Development

Apply this skill when writing new code or changing existing behavior. Forces the red-green-refactor loop that prevents bugs from being introduced and confirmed as "working."

## The loop (do not skip steps)
1. **Red** — write a failing test that describes the desired behavior. Run it. Confirm it fails for the right reason (not a syntax error or import issue).
2. **Green** — write the minimum code to make the test pass. No more. No cleanup yet.
3. **Refactor** — with tests green, clean up the implementation. Run tests after every change.

## Before writing any new function or feature
- Write the test first — describe the contract: inputs, outputs, side effects
- The test should compile (or parse) but fail when run
- If you can't write a test first, the API design is wrong — reconsider it

## What makes a good test
- Tests one specific behavior per test case (one logical assertion)
- Name states exactly what scenario is tested and what the expected outcome is
- Uses the public API — tests behavior, not internal implementation
- Does not reach into private fields to set up state
- Is independent of other tests — can run in any order, in isolation

## When to skip test-first (narrow exceptions)
- Exploratory spikes (delete after learning, do not ship)
- Pure configuration changes (no logic)
- Fixing a test itself

Even in these cases, write a test before committing the spike or configuration change to the main feature branch.

## Naming patterns
```
# Option A: BDD style
should <do X> when <condition>
should <not do X> when <condition>

# Option B: scenario style
<method>_<scenario>_<expected>
GetUser_WhenIdNotFound_ReturnsNotFound

# Option C: natural language (Go style)
TestGetUser_NotFound
```
Pick whichever the project already uses and be consistent.

## Signs you're doing it wrong
- You write code first, then write tests that confirm what you just wrote (you're testing implementation, not behavior)
- Your tests always pass on the first run (you didn't see them fail)
- Tests are deleted or commented out to make a suite pass
- A test asserts `result != nil` and nothing else
