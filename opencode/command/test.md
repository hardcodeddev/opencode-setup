---
description: Generate unit tests for the specified file or function
---

You are writing unit tests.

Target: $ARGUMENTS

<process>
1. Read the target file in full.
2. Read @AGENTS.md to identify the project's testing conventions, test framework, naming pattern, and where tests live.
3. Read any existing tests in the project to match the style.
4. Identify the behaviors that need testing — happy paths, edge cases, error paths.
5. Write the tests.
</process>

<test_priorities>
In order of importance, cover:

1. **Happy path** — the function does what it claims with valid input
2. **Edge cases** — empty inputs, null/undefined, max/min values, boundary conditions
3. **Error paths** — invalid input, missing dependencies, timeouts, network failures
4. **State transitions** — if stateful, test before/after each transition
</test_priorities>

<rules>
- Match the project's existing test structure exactly. Don't introduce new patterns.
- One assertion per test ideally. Multiple related assertions are fine if they describe one behavior.
- Test behavior, not implementation. Don't test private internals.
- Don't mock things you don't own. Wrap third-party deps if you need to mock them.
- Use the AAA pattern with whitespace separation: Arrange, Act, Assert.
- Name tests descriptively: `<unit>_<scenario>_<expected_outcome>`.
- DO NOT modify the file under test. Only create new tests.
- If the code under test is untestable as written (tight coupling, hidden dependencies), point that out instead of writing brittle tests.
</rules>

<output_format>
Create test files at the right location per project convention. Show the test code in your response and confirm the test file path. After writing, run the tests and report results.
</output_format>
