---
description: Safely refactor code — tests first, no behavior change, one step at a time
---

You are doing a safe, disciplined refactor. The contract: behavior must not change. If you cannot verify that, you do not proceed.

Target: `$ARGUMENTS` (file, function, or module to refactor)

## The refactoring rule
Refactoring = changing structure without changing behavior. If the task also involves changing behavior, that is a separate commit. Do not mix them.

## Steps

1. **Understand first**
   - Read the target file(s) in full
   - Read `AGENTS.md` for conventions and the testing framework
   - Run the existing tests and confirm they pass: record the output

2. **Identify the smell**
   Diagnose what specifically needs improving (pick one per refactor):
   - Duplicated logic → extract function/class
   - Function too long → decompose into named steps
   - Magic numbers/strings → named constants
   - Deep nesting → early returns / guard clauses
   - Unclear names → rename with intent-revealing names
   - Missing abstraction → introduce interface/type
   - Tangled concerns → separate responsibilities

3. **Safety check — can you verify behavior is preserved?**
   - Are there tests covering the code being changed? If NO, write the tests BEFORE refactoring. Do not skip this.
   - If you cannot write tests because the code is untestable, say so and explain why (e.g., depends on global state, side effects, no seam). Do not proceed blindly.

4. **Refactor in the smallest possible steps**
   - One rename → run tests → pass → next step
   - Do not batch large changes in one go
   - Never change logic while renaming
   - Use the language's refactoring tools if available (LSP rename, extract)

5. **Run tests after every step** and confirm they still pass

6. **Review your own diff** before reporting done:
   - Does any line change observable behavior?
   - Did you accidentally change a return value, error message, or condition?
   - Are all original tests still passing?

7. Report what was changed and why

## What NOT to do
- Do NOT change behavior in a refactor commit
- Do NOT add new features during a refactor
- Do NOT remove error handling "to simplify"
- Do NOT change public API signatures without explicit permission
- Do NOT proceed if tests are red at the start — fix them first

## Output
```
Refactored: <what was changed>
Reason: <smell that was fixed>
Tests: <N> passing before, <N> passing after
Behavior preserved: yes
```
