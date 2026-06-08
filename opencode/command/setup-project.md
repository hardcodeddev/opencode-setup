---
description: Initialize a project for OpenCode — installs the setup repo if needed, detects or accepts tech stack, and generates a tailored AGENTS.md
---

You are initializing a project to work with OpenCode. This command does three things in order:

1. **Bootstrap** — ensure the opencode-setup repo and all its commands/agents/skills are installed locally
2. **Detect** — auto-detect the project's tech stack from existing files (or use `$ARGUMENTS` if provided)
3. **Generate** — write a tailored `AGENTS.md` to the current project root

Tech stack hint from user: `$ARGUMENTS`
(Empty = fully auto-detect. Examples: `typescript next.js postgresql`, `python fastapi redis security`, `dotnet asp.net-core sqlserver`, `go gin postgres`, `rust axum sqlite`)

---

## Phase 1: Bootstrap opencode-setup

Run these checks and actions in sequence:

```bash
SETUP_REPO="https://github.com/hardcodeddev/opencode-setup.git"
SETUP_DIR="$HOME/.local/share/opencode-setup"
OPENCODE_CONFIG="$HOME/.config/opencode"

# 1a. Clone the setup repo if not already present
if [ ! -d "$SETUP_DIR/.git" ]; then
  echo "Cloning opencode-setup..."
  git clone "$SETUP_REPO" "$SETUP_DIR"
else
  echo "opencode-setup already present at $SETUP_DIR"
  git -C "$SETUP_DIR" pull --ff-only 2>/dev/null || echo "(pull skipped — local changes present)"
fi

# 1b. Install commands if missing or outdated
mkdir -p "$OPENCODE_CONFIG/command"
cp -r "$SETUP_DIR/opencode/command/"* "$OPENCODE_CONFIG/command/" 2>/dev/null && echo "Commands installed" || true

# 1c. Install agents if missing or outdated
mkdir -p "$OPENCODE_CONFIG/agent"
cp -r "$SETUP_DIR/opencode/agent/"* "$OPENCODE_CONFIG/agent/" 2>/dev/null && echo "Agents installed" || true

# 1d. Install skills if missing or outdated
mkdir -p "$OPENCODE_CONFIG/skills"
cp -r "$SETUP_DIR/opencode/skills/"* "$OPENCODE_CONFIG/skills/" 2>/dev/null && echo "Skills installed" || true
```

Report the result: installed / already up to date / failed (with reason).

---

## Phase 2: Detect the project tech stack

Run the following checks in the current working directory to gather facts. Collect all findings before moving to Phase 3.

```bash
# Project root indicators
ls -la
git remote -v 2>/dev/null || echo "No git remote"
git log --oneline -1 2>/dev/null || echo "No git history"
```

Then check for these files and read them for tech stack signals:

<detection_checks>

**JavaScript / TypeScript**
- `cat package.json 2>/dev/null` — read `name`, `description`, `scripts`, `dependencies`, `devDependencies`
  - Framework signals: `next`, `react`, `vue`, `svelte`, `express`, `fastify`, `hono`, `nest`
  - Test signals: `jest`, `vitest`, `mocha`, `jasmine`, `@testing-library`
  - DB client signals: `prisma`, `drizzle`, `typeorm`, `pg`, `mysql2`, `mongoose`, `redis`
  - Build signals: `vite`, `webpack`, `turbo`, `tsup`, `esbuild`
- `cat tsconfig.json 2>/dev/null` — confirms TypeScript; read `strict`, `target`, `paths`
- `cat .eslintrc* 2>/dev/null || cat eslint.config* 2>/dev/null` — linting config
- `ls pnpm-lock.yaml yarn.lock package-lock.json 2>/dev/null` — package manager

**Python**
- `cat pyproject.toml 2>/dev/null` — read `[project]` and `[tool.*]` sections
  - Framework: `fastapi`, `flask`, `django`, `litestar`, `starlette`
  - Test: `pytest`, `unittest`
  - DB: `sqlalchemy`, `alembic`, `tortoise`, `beanie`, `redis`
  - Linting: `ruff`, `flake8`, `mypy`, `pyright`
- `cat requirements.txt requirements-dev.txt 2>/dev/null`
- `cat setup.py setup.cfg 2>/dev/null`
- `ls uv.lock poetry.lock Pipfile.lock 2>/dev/null` — package manager

**Go**
- `cat go.mod 2>/dev/null` — read module name and Go version
  - Framework: `gin`, `echo`, `fiber`, `chi`, `gorilla/mux`, `connectrpc`
  - DB: `pgx`, `sqlx`, `gorm`, `ent`, `bun`, `go-redis`
  - Test: standard `testing` package (default for Go)

**.NET / C#**
- `find . -name "*.csproj" -maxdepth 3 2>/dev/null | head -5`
- `find . -name "*.sln" -maxdepth 2 2>/dev/null | head -3`
- `cat $(find . -name "*.csproj" -maxdepth 3 | head -1) 2>/dev/null` — read `TargetFramework`, `PackageReference` entries
  - Framework: `Microsoft.AspNetCore`, `Blazor`, `Minimal APIs`
  - Test: `xunit`, `nunit`, `mstest`, `bunit`
  - DB: `EntityFrameworkCore`, `Dapper`, `npgsql`, `SqlServer`

**Rust**
- `cat Cargo.toml 2>/dev/null` — read `[dependencies]`
  - Framework: `axum`, `actix-web`, `rocket`, `warp`
  - DB: `sqlx`, `diesel`, `sea-orm`
  - Test: built-in `#[test]`

**Java / JVM**
- `cat pom.xml 2>/dev/null | head -80` — read groupId, artifactId, dependencies
- `cat build.gradle build.gradle.kts 2>/dev/null | head -80`
  - Framework: `spring-boot`, `quarkus`, `micronaut`, `ktor`
  - Test: `junit`, `testng`, `kotest`, `mockito`
  - DB: `spring-data`, `hibernate`, `jooq`, `r2dbc`

**Ruby**
- `cat Gemfile 2>/dev/null`
  - Framework: `rails`, `sinatra`, `hanami`
  - Test: `rspec`, `minitest`
  - DB: `activerecord`, `sequel`, `pg`, `redis`

**PHP**
- `cat composer.json 2>/dev/null`
  - Framework: `laravel`, `symfony`, `slim`
  - Test: `phpunit`, `pest`
  - DB: `eloquent`, `doctrine`

**Database and infrastructure**
- `find . -name "docker-compose*.yml" -maxdepth 2 2>/dev/null | xargs cat 2>/dev/null | grep -E "image:|postgres|mysql|redis|mongo|kafka" | head -20`
- `find . -name "*.env.example" -maxdepth 2 2>/dev/null | xargs cat 2>/dev/null | grep -iE "DATABASE|REDIS|MONGO|KAFKA|RABBIT" | head -20`
- `find . -name "*.tf" -maxdepth 3 2>/dev/null | head -3` — Terraform present?

**Project structure clues**
- `find . -type d -maxdepth 3 ! -path '*/.git/*' ! -path '*/node_modules/*' ! -path '*/.venv/*' ! -path '*/target/*' ! -path '*/bin/*' ! -path '*/obj/*' 2>/dev/null | sort | head -40`

</detection_checks>

After running all checks, compile your findings into this fact sheet (fill in what you know, leave blank what you can't determine):

```
Detected:
  Language:       <e.g., TypeScript 5.4, Python 3.12, Go 1.22, C# 12 / .NET 8>
  Framework:      <e.g., Next.js 15, FastAPI, Gin, ASP.NET Core>
  Database:       <e.g., PostgreSQL via Prisma, Redis, SQLite, none>
  Test framework: <e.g., Vitest, pytest, go test, xUnit>
  Linting:        <e.g., ESLint + Prettier, ruff, golangci-lint>
  Package mgr:    <e.g., pnpm, uv, go mod, dotnet>
  Build:          <e.g., Next.js build, vite, cargo build, dotnet build>
  Infrastructure: <e.g., Docker Compose, Terraform, Kubernetes YAMLs>
  Security flags: <e.g., auth packages present, payment library, HIPAA keywords>
  Project name:   <from package.json/go.mod/pyproject.toml/git remote>
  Repo URL:       <from git remote>
  Stage:          <prototype if no tests / active if tests exist / maintenance if version >1.0>
  Has tests:      <yes/no — any test files found?>
  Has docker:     <yes/no>
  Has CI:         <yes/no — .github/workflows/ or .gitlab-ci.yml?>
```

---

## Phase 3: Choose template and generate AGENTS.md

### Template selection
- **If `.NET` / `C#` detected** → use `$HOME/.local/share/opencode-setup/templates/AGENTS.dotnet.md` as the base
- **If security-sensitive** (any of: auth library, payment library, healthcare keywords, "security" in `$ARGUMENTS`) → use `$HOME/.local/share/opencode-setup/templates/AGENTS.security-first.md` as the base
- **Otherwise** → use `$HOME/.local/share/opencode-setup/templates/AGENTS.generic.md` as the base

Read the chosen template with:
```bash
cat <chosen-template-path>
```

### Filling in the template

Replace every `<placeholder>` in the template with the real value you detected. For sections you couldn't detect, either fill them with a sensible default or leave a clearly-marked `TODO:` so the developer knows what to fill in.

Specific substitutions:

| Placeholder | Fill with |
|---|---|
| `<project-name>` | Detected name from package.json / go.mod / git remote / directory name |
| `<one-sentence description>` | Infer from README.md first line if present, otherwise from repo name + framework |
| `<prototype \| active development \| maintenance>` | Based on whether tests exist, version number |
| Language line | Exact detected version (e.g., `TypeScript 5.4`, `Go 1.22.3`) |
| Framework line | Exact detected framework + version from lockfile/go.mod |
| Database line | Detected DB + ORM/client (e.g., `PostgreSQL via Prisma 5.x`) |
| Testing line | Detected test framework + any assertion library |
| Linting line | Detected linter(s) |
| Package manager line | Detected package manager |
| Install command | Exact command for this project (e.g., `pnpm install`, `uv sync`, `go mod download`) |
| Dev server command | Detected from scripts / Makefile / README |
| Test command | Detected from scripts / Makefile (e.g., `pnpm test`, `pytest`, `go test ./...`) |
| Lint command | Detected from scripts (e.g., `pnpm lint`, `ruff check .`) |
| Build command | Detected from scripts |
| `<project-name>` in structure section | Fill with actual top-level directories found |

For the **Project structure** section: replace the example directory tree with the ACTUAL structure discovered in Phase 2 (`find` output). List real directories and a one-line description of what lives in each.

For the **Git workflow** section: always include the git safety rules verbatim (these are non-negotiable — do not soften them).

For the **Glossary** section: if you can infer any domain terms from the project name, README, or file names, add them. Otherwise leave the placeholder with a `TODO:`.

### Security flag handling

If any of the following are detected, add a comment at the top of the generated `AGENTS.md`:
```markdown
<!-- SECURITY NOTE: This project handles [auth / payments / PII / healthcare data].
     Consider using templates/AGENTS.security-first.md instead of the generic template.
     Run /security after every diff. -->
```

Triggers: presence of `stripe`, `braintree`, `paypal`, `passport`, `oauth`, `jwt`, `auth0`, `cognito`, `hipaa`, `phi`, `pii`, `gdpr`, `bcrypt`, `argon2` in dependencies.

### Write the file

Write the completed AGENTS.md to the project root. If an AGENTS.md already exists, read it first and ask the developer:
> "An AGENTS.md already exists. Do you want me to (1) overwrite it, (2) merge my findings into it, or (3) show a diff and let you decide?"
Do NOT overwrite without confirmation.

---

## Phase 4: Summary report

After completing all phases, report:

```
opencode-setup: installed / updated at ~/.local/share/opencode-setup
Commands:  installed (N total)
Agents:    installed (N total)
Skills:    installed (N total)

Project detected:
  Name:       <name>
  Stack:      <language> + <framework> + <database>
  Tests:      <yes/no>
  Template:   <which template was used>

AGENTS.md:  written to <path>

Next steps:
  1. Review AGENTS.md — fill in any TODO: sections
  2. Run /security to audit existing code
  3. Run /branch feat/<first-feature> to start your first feature branch
  4. Use @git-guardian for all git operations
```
