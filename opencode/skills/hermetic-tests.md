# Skill: Hermetic Test Writing

Apply this skill when writing integration tests or any test that touches infrastructure (database, HTTP, file system, time, random).

## The hermetic checklist (every test must pass all of these)

- [ ] Creates all state it needs — no dependency on data left by another test
- [ ] Cleans up all state in `afterEach`/`defer`/`finally` — runs even on failure
- [ ] No real external I/O — database, network, file system (outside temp), cloud services
- [ ] Deterministic — same result every run, on every machine
- [ ] Order-independent — passes whether run first, last, or in parallel
- [ ] Fixed time — injects a `fixedClock(2024-01-15T00:00:00Z)`, never calls real `Date.now()`
- [ ] Fixed randomness — seeded RNG or hardcoded test values, no real UUID generation

## Faking strategy by dependency type

**Database**: Use SQLite/H2 in-memory, or Testcontainers for an ephemeral real DB
```python
# Python example
engine = create_engine("sqlite:///:memory:")
Base.metadata.create_all(engine)
```

**HTTP client**: Intercept at transport layer — never call real URLs
```javascript
// JavaScript (msw)
const server = setupServer(
  rest.get("/api/users/:id", (req, res, ctx) =>
    res(ctx.json({ id: req.params.id, name: "Alice" }))
  )
);
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

**File system**: Use language-provided temp dir, auto-cleaned
```go
// Go
dir := t.TempDir() // cleaned up when test finishes
```

**Time**: Inject a clock interface
```typescript
interface Clock { now(): Date; }
const fixedClock: Clock = { now: () => new Date("2024-01-15T00:00:00Z") };
const subject = new MyService({ clock: fixedClock });
```

**Message queue**: Use an in-process fake
```go
queue := fakemq.New()
subject := NewWorker(queue)
queue.Publish("topic", payload)
subject.Process()
assert.Equal(t, 1, queue.ProcessedCount())
```

## Anti-patterns — never write these

```javascript
// WRONG: sleeps instead of awaiting
await new Promise(r => setTimeout(r, 500));

// WRONG: real network call
const res = await fetch("https://api.example.com/data");

// WRONG: shared global state between tests
let globalDb; // set once in beforeAll, shared across all tests

// WRONG: real time
expect(result.createdAt).toBeCloseTo(Date.now(), -3); // flaky

// WRONG: test depends on another test's data
it("should update user", () => {
  // assumes "create user" test ran first and left user with id=1
  updateUser(1, { name: "Bob" });
});
```

## Cleanup pattern
```typescript
// Always use this pattern — runs even if test throws
afterEach(async () => {
  await db.truncateAll();
  server.resetHandlers();
  jest.restoreAllMocks();
});
```
