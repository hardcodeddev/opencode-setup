# Skill: Performance Analysis

Apply this skill when analyzing code for performance bottlenecks or when asked to optimize. Measure first, optimize second — never guess.

## The performance workflow
1. **Profile before optimizing** — never change code for performance without a benchmark showing a problem
2. **Identify the bottleneck** — 90% of time is in 10% of the code; find that 10%
3. **Change one thing at a time** — so you know what worked
4. **Measure after** — confirm the improvement with numbers, not intuition
5. **Check for regressions** — correctness first, then speed

## Common bottleneck categories

### Algorithmic complexity
- O(n²) nested loops over large collections — can it be O(n log n) with a sort, or O(n) with a hash map?
- Repeated linear scans of the same collection — build an index once
- Recursive functions without memoization on overlapping subproblems

### Database queries
- N+1 query pattern: loading a collection, then querying each item individually — batch with IN clause or JOIN
- Missing index on a WHERE or JOIN column — check `EXPLAIN`/`EXPLAIN ANALYZE`
- Loading full rows when only one column is needed — `SELECT id` not `SELECT *`
- Unbounded queries with no LIMIT on large tables

### Memory allocation
- Creating large temporary objects inside hot loops — move allocations outside the loop
- Building strings with `+` in a loop — use a builder/buffer
- Materializing large collections into memory when streaming would work

### I/O and latency
- Sequential I/O that could be parallel — use `Promise.all`, goroutines, async gather
- Synchronous I/O blocking an async runtime — identify and fix blocking calls
- Repeated calls to the same external service with identical inputs — add a cache with TTL

### Caching
- When to cache: data is expensive to compute, read frequently, and changes infrequently
- What to cache: computation results, external API responses, parsed configs
- When NOT to cache: data that changes frequently, user-specific data (cache invalidation is hard)

## What NOT to do
- Do not optimize without a measurement showing a real problem
- Do not introduce complexity (caches, indices, async) without confirming the bottleneck is there
- Do not sacrifice correctness for micro-optimizations
- Do not prematurely abstract for "future performance" — wait until it's actually slow

## Output format when analyzing performance
```
Bottleneck found: <file>:<line>
Category: <algorithmic / db / memory / I/O / caching>
Current complexity: <O(n²)> or <N+1 queries> etc.
Impact: <estimated — low/medium/high, and why>
Fix: <specific change>
Expected improvement: <rough estimate based on reasoning>
Measurement approach: <how to verify improvement>
```
