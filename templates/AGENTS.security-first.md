# AGENTS.md — Security-First Project Template

> Use this template for projects handling sensitive data, authentication, payments, healthcare, or any context where security is a primary concern. More prescriptive than the generic template.

---

# AGENTS.md

This document is the source of truth for project conventions, architecture, and security rules. Read it fully before making any changes.

## Non-negotiable rules

<rules>
1. **NEVER push to `main` or `master`** — all work happens on feature branches.
2. **NEVER merge a pull request** — PRs are reviewed and merged by a human developer.
3. **NEVER commit secrets, credentials, keys, or tokens** — use a secrets manager.
4. **NEVER disable security mechanisms** (TLS verification, CSRF protection, auth middleware) even temporarily for debugging.
5. **NEVER use `eval()`, `exec()`, `system()` with untrusted data** — ever.
6. **NEVER store passwords in plaintext or with weak hashing** (MD5, SHA1, SHA256 alone).
7. **MUST** validate all user input at the boundary — never trust input from any external source.
8. **MUST** authenticate AND authorize every protected operation — never assume one implies the other.
9. **MUST** write a test for every behavioral change.
10. **MUST** run `/security` audit on every diff before creating a PR.
</rules>

## Project overview

<project>
- **Name**: <project-name>
- **Purpose**: <one-sentence description>
- **Sensitivity level**: <public | internal | confidential | restricted>
- **Data handled**: <e.g., user PII, payment data, health records, auth tokens>
- **Compliance context**: <e.g., GDPR, HIPAA, PCI-DSS, SOC2, none>
- **Stage**: <prototype | active development | maintenance>
</project>

## Tech stack

<stack>
- **Language**: <e.g., TypeScript 5.4, Python 3.12, Go 1.22>
- **Framework**: <e.g., Next.js 15, FastAPI, Gin>
- **Database**: <e.g., PostgreSQL, MongoDB>
- **Auth**: <e.g., Auth0, Supabase Auth, custom JWT, session-based>
- **Testing**: <e.g., Vitest, pytest, go test>
- **Linting / SAST**: <e.g., ESLint + eslint-plugin-security, bandit, gosec>
- **Package manager**: <e.g., pnpm, uv, go mod>
- **Secrets management**: <e.g., HashiCorp Vault, AWS Secrets Manager, .env (dev only)>
</stack>

## Project structure

<structure>
```
src/
  routes/         # HTTP handlers — auth middleware applied here
  services/       # Business logic — where authorization checks live
  data/           # Database access — always parameterized queries
  models/         # Data types — sensitive fields marked
  middleware/     # Auth, rate limiting, CORS, headers
  crypto/         # All crypto operations centralized here
tests/
  unit/
  integration/    # Hermetic (see testing section)
  security/       # Explicit security test scenarios
```
</structure>

## Authentication & Authorization

<auth>
### Authentication
- Every request that needs identity must validate the session/token before any logic runs
- Token validation: signature, expiry (`exp`), issuer (`iss`), audience (`aud`)
- JWT algorithm: RS256 or ES256 — never `alg: none`, never HS256 with a guessable secret
- Session IDs: cryptographically random, min 128 bits
- Session regeneration: always regenerate after login, privilege escalation, or role change
- Failed auth attempts: rate-limit, log (without the credential), and return generic error messages

### Authorization
- Check object ownership in every data access: verify `record.userId === req.user.id`
- Role checks must be explicit — never infer "user has role X because they can do Y"
- Deny by default — if the user's permission is not explicitly granted, deny
- Never use `isAdmin` flags in JWTs that can be self-signed by clients
</auth>

## Cryptography standards

<crypto>
- **Password hashing**: `bcrypt` (cost ≥12), `argon2id`, or `scrypt` — ONLY these
- **Token generation**: OS cryptographic RNG (`secrets.token_urlsafe`, `crypto.randomBytes`, `crypto/rand`)
- **Symmetric encryption**: AES-256-GCM — unique nonce per encryption, authenticated
- **Asymmetric**: RSA-2048+ or P-256 ECDSA
- **TLS**: minimum TLS 1.2, prefer 1.3 — never disable cert verification
- **Never use**: MD5, SHA1 for security purposes, DES, 3DES, RC4, ECB mode
- All crypto operations live in `src/crypto/` — never ad-hoc throughout the codebase
</crypto>

## Input validation rules

<validation>
- Validate at the boundary — the moment data enters from outside (HTTP, queue, file)
- Validate: type, length (min AND max), format, range
- Reject unknown fields — do not silently pass them through
- Sanitize for the output context (HTML-escape, SQL-parameterize, shell-escape)
- File uploads: validate MIME type (not just extension), set hard size limit, scan filename for path traversal

### Required validators
```
User ID:     UUID v4 format
Email:       RFC 5321, max 254 chars
Password:    8-128 chars (at input), never store raw
Free text:   max <N> chars (project-specific), strip null bytes
File name:   alphanumeric + hyphen/underscore/dot, no path separators
```
</validation>

## Secrets management

<secrets>
- Production secrets: secrets manager only (Vault, AWS SM, GCP SM)
- Development secrets: `.env` file, NEVER committed (always in `.gitignore`)
- No secrets in: source code, git history, log output, error messages, URLs
- Rotation: secrets must be rotatable without a deploy
- Audit: all secret access logged at the secrets manager level

### Pre-commit secret scan
Before every commit, verify no staged file contains:
- `-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----`
- `sk-[a-zA-Z0-9]{40,}` (OpenAI/Anthropic keys)
- `AKIA[A-Z0-9]{16}` (AWS access key)
- `ghp_[a-zA-Z0-9]{36}` (GitHub token)
- `password\s*=\s*["'][^"']{6,}` (inline passwords)
</secrets>

## Logging rules

<logging>
Log events: auth success/failure (without credential), access to sensitive resources, admin actions, errors
NEVER log: passwords, tokens, session IDs, full request bodies containing PII, credit card numbers, SSNs
Format: structured JSON with: timestamp, level, event type, user ID (not email), request ID
Retention: follow compliance requirements (GDPR: minimal; HIPAA: 6 years; PCI: 1 year)
</logging>

## Git workflow

<git>
### Branch protection
- NEVER push to `main` or `master`
- NEVER merge PRs — humans merge
- NEVER force-push to shared branches
- NEVER `--no-verify` on commits

### Workflow
1. `git fetch origin main`
2. `git checkout -b <type>/<slug> origin/main`
3. Implement and test changes
4. Run `/security` audit on the diff
5. `git push -u origin <branch>`
6. Create PR for review — include security checklist in PR description

### PR security checklist
Every PR description must include:
```markdown
## Security checklist
- [ ] No secrets or credentials in diff
- [ ] All new user input validated
- [ ] Auth middleware applied to new routes
- [ ] No new raw SQL queries
- [ ] `/security` command run — findings addressed
- [ ] Integration tests hermetic (no real external deps)
```
</git>

## Testing protocols

<testing>
- **New feature**: test written BEFORE the feature (TDD)
- **Bug fix**: regression test added — proves the bug existed and is now fixed
- **Security fix**: explicit test for the vulnerability scenario

### Unit tests
- One behavior per test
- Mock all I/O at the boundary (use the interface, not the concrete type)
- Named: `<method>_<scenario>_<expected>` or `should <do X> when <Y>`

### Hermetic integration tests
ALL integration tests must be hermetic:
- No real DB — in-memory (SQLite/H2) or Testcontainers ephemeral container
- No real HTTP — interceptor (msw, WireMock, httptest.Server)
- No real time — inject `fixedClock("2024-01-15T00:00:00Z")`
- No shared state — set up and tear down in `beforeEach`/`afterEach`
- Cleanup runs even on test failure (`defer`/`finally`/`afterEach`)
- Annotate: `// Hermetic: yes // Mocked: <list>`

### Security-specific tests
Write explicit tests for:
- Unauthorized access attempt → 401/403 (not 200, not 500)
- Accessing another user's resource → 403
- SQL injection attempt in each input → rejected, not executed
- Token with expired `exp` → rejected
- Input at max+1 length → rejected cleanly
- Missing required auth header → 401, not 500
</testing>

## HTTP security headers

<headers>
Every HTTP response must include:
```
Content-Security-Policy: default-src 'self'; script-src 'self'; ...
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=()
Strict-Transport-Security: max-age=31536000; includeSubDomains (HTTPS only)
```
CORS: never `Access-Control-Allow-Origin: *` on authenticated endpoints.
Cookies: `HttpOnly; Secure; SameSite=Strict` on session/auth cookies.
</headers>

## Code conventions

<conventions>
- **Naming**: <camelCase for variables, PascalCase for types, kebab-case for files>
- **Error handling**: never swallow errors; log with context; return typed errors
- **Async**: all I/O async; never block event loop
- **Dependencies**: review before adding — is it actively maintained? Does it have known CVEs?
- **Type safety**: use strict null checks; no `any` / unchecked type assertions
</conventions>

## Build / Run / Test

<commands>
```bash
# Install dependencies
<install command>

# Run dev server
<dev command>

# Run all tests
<test command>

# Run security-specific tests
<test command> --grep security

# Lint and format
<lint command>

# Run SAST (if configured)
<sast command, e.g., bandit -r src/ or gosec ./...>

# Build for production
<build command>
```
</commands>

## Glossary

<glossary>
- **Hermetic test**: a test with no real external dependencies — fully self-contained and deterministic
- **SAST**: Static Application Security Testing — automated code scanning for vulnerabilities
- **PII**: Personally Identifiable Information — names, emails, phone numbers, IPs in some jurisdictions
- **<Term>**: <Definition>
</glossary>

## Known quirks & security trade-offs

<quirks>
<!-- Document any intentional security trade-offs or non-obvious security decisions -->
- <e.g., "Rate limiting is handled by the reverse proxy, not application code — do not add it here.">
- <e.g., "JWT refresh tokens are stored in HttpOnly cookies, not localStorage.">
</quirks>

## When in doubt

<fallback>
- For security questions: run `/security` on the relevant code before asking
- For auth design questions: ask before implementing — auth bugs are hard to find and costly
- If you're about to disable a security check to make something work: stop and explain why first
- If a feature requires a new permission or role: flag it explicitly in the PR
- If you see a secret in existing code: note it in a comment for the developer, do NOT commit the fix silently
</fallback>
