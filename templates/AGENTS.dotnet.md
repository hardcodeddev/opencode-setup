# AGENTS.md — .NET / C# Project Starter Template

> Drop this at the root of a .NET repo as `AGENTS.md`. Fill in `<placeholders>` and trim sections that don't apply. Anything below this quote block is what the agent actually reads.

---

# AGENTS.md

You are working on a .NET / C# codebase. This document is the source of truth for project conventions, architecture, and rules. Read it before making changes.

## How to work in this project

<rules>
1. **MUST** use Plan mode for any task touching more than one file. Present a plan, wait for confirmation, then execute.
2. **MUST** read existing code in the affected area before writing new code. Match existing patterns.
3. **MUST** run `dotnet build` after any code change to verify the project compiles.
4. **MUST** run relevant tests after changes (`dotnet test` or targeted test runs).
5. **MUST NOT** commit secrets, connection strings, API keys, or credentials. Use `appsettings.{Environment}.json`, User Secrets, or environment variables.
6. **MUST NOT** suppress warnings or disable analyzers without explicit approval.
7. **MUST NOT** introduce new top-level dependencies without confirming first.
8. **SHOULD** prefer modifying existing files over creating new ones, unless project structure clearly calls for a new file.
9. **SHOULD** ask for clarification rather than guess when requirements are ambiguous.
10. **SHOULD** make commits small and focused. One logical change per commit.
</rules>

## Project overview

<project>
- **Name**: <project-name>
- **Purpose**: <one-sentence description of what this project does>
- **Domain**: <e.g., mortgage origination, e-commerce, internal tooling>
- **Stage**: <prototype | active development | maintenance>
- **Team size**: <number of contributors>
</project>

## Tech stack

<stack>
- **.NET version**: <e.g., .NET 8, .NET 9>
- **Language version**: C# <12 | 13>
- **Primary frameworks**: <ASP.NET Core Web API | Blazor Server | WPF | WinForms | Console | Worker Service>
- **ORM / data access**: <Entity Framework Core | Dapper | ADO.NET | none>
- **Database**: <SQL Server | PostgreSQL | SQLite | Cosmos DB>
- **Messaging / queuing**: <Azure Service Bus | RabbitMQ | none>
- **Caching**: <Redis | IMemoryCache | none>
- **Logging**: <Serilog | Microsoft.Extensions.Logging | NLog>
- **Testing**: <xUnit | NUnit | MSTest>
- **Mocking**: <Moq | NSubstitute | FakeItEasy>
- **Assertion library**: <FluentAssertions | Shouldly | built-in>
- **Validation**: <FluentValidation | DataAnnotations>
- **API documentation**: <Swashbuckle/Swagger | NSwag | none>
- **Hosting**: <Azure App Service | AWS | on-prem IIS | Kubernetes>
- **CI/CD**: <Azure DevOps | GitHub Actions | TeamCity>
</stack>

## Architecture

<architecture>
Default assumption: **Clean Architecture** with these layers (adjust as needed):

- `src/<Project>.Domain/` — Entities, value objects, domain events, domain exceptions. No dependencies on other layers.
- `src/<Project>.Application/` — Use cases, DTOs, interfaces for infrastructure, MediatR handlers if used. Depends only on Domain.
- `src/<Project>.Infrastructure/` — EF Core, external services, file system, third-party integrations. Implements Application interfaces.
- `src/<Project>.Api/` (or `.Web/`, `.WorkerService/`) — Composition root, controllers/endpoints, middleware, DI registration.
- `tests/<Project>.UnitTests/`
- `tests/<Project>.IntegrationTests/`

**Dependency rule**: dependencies point inward. Infrastructure depends on Application; Application depends on Domain; Domain depends on nothing.

If this project doesn't use Clean Architecture, describe the actual layout here.
</architecture>

## Code conventions

<conventions>

### Naming
- **PascalCase**: classes, methods, properties, public fields, namespaces, enum values, file names
- **camelCase**: parameters, local variables
- **_camelCase**: private fields (underscore prefix)
- **IPascalCase**: interfaces (the `I` prefix is standard in .NET, keep it)
- **PascalCaseAsync**: async methods always end in `Async`
- File name matches the primary type in the file

### Style
- Use `var` when the type is obvious from the right side, explicit type otherwise
- Expression-bodied members for simple one-liners
- Use file-scoped namespaces (`namespace Foo;` not `namespace Foo { }`)
- Use primary constructors where they reduce boilerplate (C# 12+)
- Prefer collection expressions `[1, 2, 3]` over `new[] { 1, 2, 3 }` (C# 12+)
- Use `nameof()` instead of magic strings for parameter names, property names
- Use raw string literals `"""..."""` for multi-line strings (C# 11+)

### Async/await
- All I/O is async. No `.Result`, no `.Wait()`, no `.GetAwaiter().GetResult()`.
- Pass `CancellationToken` through the call chain. Accept it as a parameter; respect it.
- Use `ConfigureAwait(false)` in library code (not needed in ASP.NET Core, since there's no sync context).
- Don't `async void` except for event handlers.

### Null safety
- Nullable reference types are **enabled** (`<Nullable>enable</Nullable>`).
- Annotate intent: `string?` vs `string`. The compiler is your friend.
- Use `ArgumentNullException.ThrowIfNull(param)` instead of manual null checks.
- Prefer pattern matching: `if (x is null)`, `if (x is not null)`.

### Exception handling
- Throw specific exceptions, not generic `Exception` or `ApplicationException`.
- Don't catch exceptions you can't handle.
- Don't swallow exceptions silently — log at minimum.
- Use `try/finally` or `using` for resource cleanup, not `try/catch/throw`.

### LINQ
- Prefer query syntax for complex joins/grouping; method syntax for simple chains.
- Watch for accidental multiple enumeration. Materialize with `.ToList()` if iterating twice.
- Use `FirstOrDefault` / `SingleOrDefault` deliberately — they mean different things.

### Strings
- Use string interpolation `$"..."` for formatting.
- Use `StringBuilder` for loops that build strings.
- Use `string.IsNullOrWhiteSpace()` not `string.IsNullOrEmpty()` when checking user input.

</conventions>

## Build / Run / Test commands

<commands>
```bash
# Restore + build
dotnet restore
dotnet build

# Run the API/Web project
dotnet run --project src/<Project>.Api

# Run with hot reload
dotnet watch --project src/<Project>.Api

# Run all tests
dotnet test

# Run a specific test project
dotnet test tests/<Project>.UnitTests

# Run a single test by name
dotnet test --filter "FullyQualifiedName~MyTestMethod"

# Format code
dotnet format

# Database migrations (EF Core)
dotnet ef migrations add <MigrationName> --project src/<Project>.Infrastructure --startup-project src/<Project>.Api
dotnet ef database update --project src/<Project>.Infrastructure --startup-project src/<Project>.Api
```
</commands>

## Testing protocols

<testing>

### Structure
- **Unit tests**: pure logic, no I/O. Live in `tests/<Project>.UnitTests/`. Should run in under 5 seconds total.
- **Integration tests**: hit real DB/external services (or testcontainers). Live in `tests/<Project>.IntegrationTests/`.

### Naming
Use the `MethodName_Scenario_ExpectedBehavior` pattern:
- `CreateUser_WhenEmailExists_ThrowsConflictException`
- `CalculateInterest_WithZeroPrincipal_ReturnsZero`

### Pattern
Arrange-Act-Assert with whitespace separation:
```csharp
[Fact]
public async Task GetOrder_WhenOrderExists_ReturnsOrder()
{
    // Arrange
    var orderId = Guid.NewGuid();
    var expected = new Order(orderId, "test");
    _repository.Setup(r => r.GetAsync(orderId, default))
        .ReturnsAsync(expected);

    // Act
    var result = await _service.GetOrderAsync(orderId, default);

    // Assert
    result.Should().BeEquivalentTo(expected);
}
```

### Rules
- One assertion per test, ideally. FluentAssertions chains are fine.
- Don't mock what you don't own (third-party libraries) — wrap them and mock the wrapper.
- Test behavior, not implementation. If a refactor breaks tests without changing behavior, the tests are too coupled.
- New features require new tests. Bug fixes require a regression test.
</testing>

## Common patterns

<patterns>

### Dependency injection
Register in `Program.cs` (or `Startup.cs`). Group related registrations into extension methods:

```csharp
// In Program.cs
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

// In Application/DependencyInjection.cs
public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(DependencyInjection).Assembly));
        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);
        return services;
    }
}
```

### Configuration binding
Use the options pattern with validation:
```csharp
builder.Services.AddOptions<DatabaseOptions>()
    .BindConfiguration("Database")
    .ValidateDataAnnotations()
    .ValidateOnStart();
```

### Logging
Use structured logging — pass parameters, don't interpolate:
```csharp
// GOOD
_logger.LogInformation("Order {OrderId} processed for user {UserId}", orderId, userId);

// BAD (loses structure, kills queryability)
_logger.LogInformation($"Order {orderId} processed for user {userId}");
```

### EF Core queries
- Use `AsNoTracking()` for read-only queries.
- Project to DTOs with `Select()` instead of loading full entities when you only need a few fields.
- Use `Include()` deliberately — N+1 queries are easy to introduce without it.
- Don't `SaveChanges()` inside loops. Batch and commit once.

### MediatR (if used)
- Commands return `Unit` or a result DTO. Queries return the DTO directly.
- One handler per request.
- Validators run as a pipeline behavior, not inside handlers.

### Result pattern (if used)
Prefer returning `Result<T>` over throwing for expected failure cases (validation, not-found, business rule violations). Reserve exceptions for unexpected errors.

</patterns>

## API conventions (if applicable)

<api>
- RESTful where it makes sense; pragmatic where it doesn't
- URLs are plural nouns: `/api/orders`, not `/api/getOrders`
- Versioning via URL path: `/api/v1/orders`
- Status codes: 200 OK, 201 Created (with Location header), 204 No Content, 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 409 Conflict, 422 Unprocessable Entity, 500 Internal Server Error
- Errors return Problem Details (RFC 7807): `application/problem+json`
- Date/time in ISO 8601 with explicit timezone, prefer UTC
- IDs in URLs are GUIDs (string form) unless there's a domain reason otherwise
</api>

## Git workflow

<git>
- Branch naming: `<type>/<short-description>` where type is `feat`, `fix`, `refactor`, `chore`, `docs`, `test`
- Example: `feat/add-rate-limiting`, `fix/null-ref-in-order-service`
- Commit messages follow Conventional Commits: `<type>(<scope>): <description>`
  - `feat(orders): add cancellation endpoint`
  - `fix(auth): handle null token in middleware`
- Squash on merge to main. Keep main history clean.
- Never force-push to shared branches.
</git>

## Performance considerations

<performance>
- Don't optimize prematurely. Measure first with BenchmarkDotNet for hot paths.
- Watch for: LINQ on hot paths (allocations), `string.Concat` in loops, accidental boxing, sync-over-async, N+1 EF queries.
- Use `Span<T>` and `Memory<T>` for parsing/serialization hot paths.
- Pool expensive objects with `ArrayPool<T>` and `ObjectPool<T>`.
</performance>

## Security baseline

<security>
- All user input is untrusted. Validate at the boundary.
- Parameterized queries only — no string concatenation into SQL.
- Use `[Authorize]` by default, `[AllowAnonymous]` explicitly when public.
- Secrets via configuration providers (User Secrets in dev, Key Vault/env vars in prod). Never in source.
- Log security events (login, authz failure, privilege change) but never log secrets, full tokens, or PII without redaction.
- Use `HttpOnly`, `Secure`, `SameSite=Strict` for auth cookies.
</security>

## Project-specific glossary

<glossary>
<!-- Define domain terms the agent should know -->
- **<Term>**: <Definition>
- **<Term>**: <Definition>
</glossary>

## Known issues / quirks

<quirks>
<!-- Things the agent should be warned about -->
- <e.g., "The legacy Reporting module uses Dapper, not EF. Don't migrate it without discussion.">
- <e.g., "External payment provider returns 200 OK with errors in the body. Always check the `success` field.">
</quirks>

## When in doubt

<fallback>
- Ask a clarifying question rather than guess.
- Show me the plan before executing destructive operations.
- If you're about to write more than 200 lines without confirming, stop and check in.
- If you need to add a new dependency, ask first.
- If something feels off (architecturally weird, security-smelling, performance trap), call it out instead of just implementing it.
</fallback>

---

## Template usage notes (delete this section in the real AGENTS.md)

**To use this template:**
1. Copy it to your repo root as `AGENTS.md`
2. Fill in all `<placeholders>`
3. Delete sections that don't apply (e.g., remove API conventions for a console app)
4. Add project-specific quirks, glossary entries, and rules
5. Commit it. Update it as you learn what trips the agent up.

**Iteration loop:**
- After every session where the agent did something dumb, ask yourself: "what could I have written in AGENTS.md to prevent this?"
- Add a rule. Save. Next session benefits.
- After 2-3 weeks of this, your AGENTS.md becomes a force multiplier.

**On length:**
- Bigger isn't better — every token here goes into context for every request.
- Aim for under 2,000 tokens (~1,500 words). Cut aggressively.
- Move stuff you reference rarely into separate files and `@reference` them in commands instead.

**For your gaming-laptop + Qwen3-Coder setup specifically:**
- The XML tags throughout this template are deliberate — Qwen models respond noticeably better to XML-structured prompts than free-form markdown.
- The explicit MUST/MUST NOT/SHOULD/MAY language follows RFC 2119, which open-source agent ecosystems (and the models trained on them) understand well.
- Keep this file lean. Your model has 32K context after the optimizations — you don't want AGENTS.md eating 20% of it.
