# Skill: Security Mindset

Apply this skill when writing any code that handles user input, authentication, data storage, or external communication. Think like an attacker building every feature.

## For every function that accepts input, ask:
1. What happens if this input is empty? Null? Negative? 10× the expected max size?
2. What if the input contains SQL metacharacters (`'`, `"`, `;`, `--`)?
3. What if the input contains shell metacharacters (`;`, `|`, `&&`, `$(...)`, backticks)?
4. What if the input contains HTML/JS (`<script>`, `javascript:`, `onload=`)?
5. What if the input contains path traversal sequences (`../`, `..\\`, `%2e%2e`)?
6. Who is allowed to call this? Is that enforced, or just assumed?

## Secrets — never do these
- Never hardcode credentials, tokens, API keys, passwords in source
- Never log authentication tokens, session IDs, or PII (email, SSN, phone)
- Never put secrets in environment variable names that appear in URLs
- Never commit `.env` files — always `.gitignore` them
- Use a secrets manager or environment injection at deploy time

## Authentication & Authorization pattern
```
1. Authenticate: who is calling? (verify identity)
2. Authorize: are they allowed to do this? (verify permission)
3. Act: perform the operation
```
Never assume step 1 or 2 already happened "somewhere else" — verify explicitly in every handler.

## Data access safety
```python
# WRONG
db.execute(f"SELECT * FROM users WHERE id = {user_id}")

# RIGHT
db.execute("SELECT * FROM users WHERE id = %s", (user_id,))
```
Always use parameterized queries or an ORM with auto-escaping. Never format user data into SQL strings.

## Cryptography defaults
- Passwords: `bcrypt` (cost ≥12), `argon2id`, or `scrypt` — never MD5/SHA1/SHA256 bare
- Random tokens: use cryptographically secure RNG — `secrets.token_urlsafe()` (Python), `crypto.randomBytes()` (Node), `crypto/rand` (Go)
- Encryption: AES-256-GCM — never ECB mode, never hardcoded IV
- TLS: never disable certificate verification

## Output encoding
- HTML context: HTML-escape (`&`, `<`, `>`, `"`, `'`)
- URL context: percent-encode
- JS context: JSON-encode or use a safe template — never string-concatenate user data into JS
- Shell context: use argument arrays, never string interpolation

## What good security hygiene looks like in a PR
- Every new route/endpoint has explicit auth middleware or is explicitly marked public
- No new raw string SQL queries
- No new `exec`/`system` calls with untrusted data
- No new hardcoded credentials
- New dependencies are well-known packages with clear purpose
- Sensitive fields are not returned in API responses unless needed
