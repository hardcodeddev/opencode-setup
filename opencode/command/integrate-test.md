---
description: Generate hermetic integration tests for a module or feature — fully self-contained, no real external dependencies
---

You are writing hermetic integration tests. "Hermetic" means: the test owns all its state, never touches real external services, is deterministic on every machine, and cleans up after itself unconditionally.

Target: `$ARGUMENTS` (file path, module name, or feature description)

## What hermetic means (enforce all of these)
- **No real I/O**: no real databases, no real HTTP calls, no real filesystems outside a temp directory
- **No shared state**: each test creates its own fixtures and tears them down — even if a previous test panics
- **Deterministic**: no `time.Now()` / `Date.now()` / `random()` without seeding or injection; use fixed timestamps
- **Order-independent**: tests pass in any execution order, in parallel if the framework supports it
- **Self-describing**: the test name alone tells you what scenario is being verified

## Allowed isolation strategies (pick the right one per scenario)
| Scenario | Strategy |
|---|---|
| Database queries | In-memory DB (SQLite, H2, testcontainers) or repository mock |
| HTTP/REST clients | HTTP interceptor (nock, msw, WireMock, httptest.Server) |
| File system | `os.TempDir()` / `t.TempDir()`, cleaned up in `defer` / `afterEach` |
| Time | Inject a clock interface; use fixed `2024-01-15T00:00:00Z` in tests |
| External queues | In-memory fake (e.g., fake SQS, fake Kafka) |
| Email/SMS | Stub that records calls for assertion |
| Random data | Seeded RNG or fixed test fixtures |

## Steps

1. Read the target file(s) fully.
2. Read `AGENTS.md` for the project's testing framework, conventions, and coverage targets.
3. Read existing integration tests (if any) to match style exactly.
4. Identify the integration points: what external resources does this code touch?
5. For each integration point, choose the correct isolation strategy from the table above.
6. Identify test scenarios:
   - Happy path (complete, realistic workflow)
   - Error path (external dependency fails, returns error code)
   - Boundary conditions (empty input, max size, concurrency if relevant)
   - Cleanup validation (resources released even on failure)
7. Write tests following the project's conventions:
   - Name pattern: `<Action>_<Scenario>_<Expected>` or `should <do X> when <Y>`
   - AAA structure: Arrange (setup) → Act (invoke) → Assert (verify) → Cleanup (defer/finally/afterEach)
   - Assert the contract (output, state, side effects), not the implementation
8. Add a comment block at the top of each test file:
   ```
   // Hermetic: yes
   // External deps mocked: <list>
   // Cleanup: defer/afterEach/finalizer
   ```
9. Run the tests and confirm they pass and are stable (run twice — identical output both times).

## What to NOT do
- Do NOT call real APIs, real databases, or real file paths outside temp dirs
- Do NOT `time.Sleep` for async coordination — use channels, callbacks, or polling with timeout
- Do NOT leave temp files, test DB records, or started services alive after the test
- Do NOT test internal functions through white-box reaching — test the public API
- Do NOT write a test that passes once and flakes on the second run

## Output format
After writing, report:
```
Tests written: <N>
File: <path>
Coverage added: <what scenarios are now tested>
Isolation: <what was mocked/faked and how>
Hermetic check: <confirm no real external dependencies>
```
