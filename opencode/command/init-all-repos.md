---
description: One-time bootstrapper — scans all your git repos, detects each project's tech stack, and writes a tailored AGENTS.md to each one. Run once to onboard your whole machine.
---

You are running a one-time bulk initialization across all git repositories on this machine. This command finds every repo, detects its tech stack with a fast sniff (not a deep read), proposes which template to apply, shows you the full plan, waits for your confirmation, then writes the files.

Arguments: `$ARGUMENTS`

Recognized flags (space-separated anywhere in arguments):
- `--dry-run` — show the plan but write nothing (default if no flag given and this is the first run)
- `--write` — after showing the plan, proceed with writing
- `--overwrite` — rewrite AGENTS.md even if one already exists (implies --write)
- `--skip-existing` — skip repos that already have AGENTS.md (default behavior with --write)
- `--path <dir>` — scan only under this directory instead of all common locations

**Default behavior with no arguments**: dry-run only. Shows the full plan. To actually write, re-run with `--write`.

---

## Phase 1: Find all git repositories

Search the common locations where developers keep code. Do NOT recurse into `node_modules`, `.venv`, `vendor`, `target`, `.git`, or other dependency/build directories.

```bash
# Search common developer directories, max depth 5, find .git markers
find_repos() {
  local search_roots=(
    "$HOME"
    "$HOME/projects"
    "$HOME/code"
    "$HOME/dev"
    "$HOME/src"
    "$HOME/work"
    "$HOME/workspace"
    "$HOME/repos"
    "$HOME/git"
    "$HOME/Development"
    "$HOME/Developer"
    "$HOME/Documents/projects"
    "$HOME/Documents/code"
    "$HOME/Documents/dev"
  )

  # Deduplicate and only include dirs that exist
  local existing_roots=()
  for d in "${search_roots[@]}"; do
    [ -d "$d" ] && existing_roots+=("$d")
  done

  # Find .git directories (marks a repo root), prune deep dives
  find "${existing_roots[@]}" \
    -maxdepth 6 \
    -name ".git" \
    -type d \
    -not -path "*/node_modules/*" \
    -not -path "*/.venv/*" \
    -not -path "*/vendor/*" \
    -not -path "*/target/*" \
    -not -path "*/__pycache__/*" \
    -not -path "*/build/*" \
    -not -path "*/dist/*" \
    2>/dev/null \
    | sed 's|/.git$||' \
    | sort -u
}
find_repos
```

If `--path` was given, replace the search with:
```bash
find "<given-path>" -maxdepth 6 -name ".git" -type d \
  -not -path "*/node_modules/*" -not -path "*/.venv/*" \
  -not -path "*/vendor/*" -not -path "*/target/*" \
  2>/dev/null | sed 's|/.git$||' | sort -u
```

Collect the list of repo paths. If more than 100 repos are found, warn:
> "Found N repos. That's a lot — consider using `--path ~/projects` to scope the scan. Continuing..."

---

## Phase 2: Fast stack detection for each repo

For each repo path, run ONLY these lightweight checks (no deep reads — just sniff the root and one level down):

```bash
sniff_repo() {
  local repo="$1"
  local indicators=""

  # Check root-level indicator files only
  [ -f "$repo/package.json" ]          && indicators="$indicators nodejs"
  [ -f "$repo/tsconfig.json" ]         && indicators="$indicators typescript"
  [ -f "$repo/go.mod" ]                && indicators="$indicators go"
  [ -f "$repo/pyproject.toml" ]        && indicators="$indicators python"
  [ -f "$repo/requirements.txt" ]      && indicators="$indicators python"
  [ -f "$repo/Pipfile" ]               && indicators="$indicators python"
  [ -f "$repo/Cargo.toml" ]            && indicators="$indicators rust"
  [ -f "$repo/pom.xml" ]               && indicators="$indicators java"
  [ -f "$repo/build.gradle" ] || \
  [ -f "$repo/build.gradle.kts" ]      && indicators="$indicators java"
  [ -f "$repo/Gemfile" ]               && indicators="$indicators ruby"
  [ -f "$repo/composer.json" ]         && indicators="$indicators php"
  [ -f "$repo/mix.exs" ]               && indicators="$indicators elixir"
  [ -f "$repo/AGENTS.md" ]             && indicators="$indicators has_agents_md"
  [ -d "$repo/.github/workflows" ]     && indicators="$indicators has_ci"

  # Quick framework sniff from package.json if present (one grep, no full read)
  if [ -f "$repo/package.json" ]; then
    grep -qE '"next"' "$repo/package.json" 2>/dev/null       && indicators="$indicators next"
    grep -qE '"react"' "$repo/package.json" 2>/dev/null      && indicators="$indicators react"
    grep -qE '"vue"' "$repo/package.json" 2>/dev/null        && indicators="$indicators vue"
    grep -qE '"svelte"' "$repo/package.json" 2>/dev/null     && indicators="$indicators svelte"
    grep -qE '"express"' "$repo/package.json" 2>/dev/null    && indicators="$indicators express"
    grep -qE '"fastify"' "$repo/package.json" 2>/dev/null    && indicators="$indicators fastify"
    grep -qE '"vitest"' "$repo/package.json" 2>/dev/null     && indicators="$indicators vitest"
    grep -qE '"jest"' "$repo/package.json" 2>/dev/null       && indicators="$indicators jest"
    grep -qE '"prisma"' "$repo/package.json" 2>/dev/null     && indicators="$indicators prisma"
    # Security-sensitive signals
    grep -qE '"stripe|braintree|paypal"' "$repo/package.json" 2>/dev/null  && indicators="$indicators payments"
    grep -qE '"passport|jsonwebtoken|auth0|@clerk"' "$repo/package.json" 2>/dev/null && indicators="$indicators auth"
    grep -qE '"bcrypt|argon2"' "$repo/package.json" 2>/dev/null            && indicators="$indicators crypto_deps"
  fi

  # .NET / C# sniff
  if find "$repo" -maxdepth 2 -name "*.csproj" 2>/dev/null | grep -q .; then
    indicators="$indicators dotnet"
    grep -qrE "Blazor|blazor" "$repo" --include="*.csproj" --include="*.cs" \
      -l --max-count=1 2>/dev/null && indicators="$indicators blazor"
  fi

  # Python framework sniff
  if [ -f "$repo/pyproject.toml" ] || [ -f "$repo/requirements.txt" ]; then
    grep -qE 'fastapi|flask|django|starlette' \
      "$repo/pyproject.toml" "$repo/requirements.txt" 2>/dev/null \
      && indicators="$indicators $(grep -ohE 'fastapi|flask|django' \
          "$repo/pyproject.toml" "$repo/requirements.txt" 2>/dev/null | head -1)"
    grep -qE 'stripe|cryptography|bcrypt|PyJWT|authlib' \
      "$repo/pyproject.toml" "$repo/requirements.txt" 2>/dev/null \
      && indicators="$indicators auth_or_payments"
  fi

  # Go framework sniff
  if [ -f "$repo/go.mod" ]; then
    grep -qE 'gin-gonic|echo|fiber|chi|gorilla' "$repo/go.mod" 2>/dev/null \
      && indicators="$indicators $(grep -ohE 'gin|echo|fiber|chi' "$repo/go.mod" 2>/dev/null | head -1)"
  fi

  echo "$indicators"
}
```

Run this for each repo. Collect results into a table:

```
REPO_PATH | INDICATORS | PROPOSED_TEMPLATE | EXISTING_AGENTS_MD | ACTION
```

---

## Phase 3: Classify each repo and assign a template

Using the indicator list from Phase 2, apply this decision table for each repo:

| Indicators contain | Proposed template | Stack label |
|---|---|---|
| `dotnet` | `AGENTS.dotnet.md` | `.NET / C#` |
| `payments` OR `auth` OR `crypto_deps` OR `auth_or_payments` (any language) | `AGENTS.security-first.md` | `<lang> + security-sensitive` |
| `nodejs` + `typescript` | `AGENTS.generic.md` | `TypeScript` |
| `nodejs` (no typescript) | `AGENTS.generic.md` | `JavaScript` |
| `go` | `AGENTS.generic.md` | `Go` |
| `python` | `AGENTS.generic.md` | `Python` |
| `rust` | `AGENTS.generic.md` | `Rust` |
| `java` | `AGENTS.generic.md` | `Java / JVM` |
| `ruby` | `AGENTS.generic.md` | `Ruby` |
| `php` | `AGENTS.generic.md` | `PHP` |
| none of the above | `AGENTS.generic.md` | `Unknown` |

For the action column:
- If `has_agents_md` and NOT `--overwrite` → `SKIP (AGENTS.md exists)`
- If `has_agents_md` and `--overwrite` → `OVERWRITE`
- Otherwise → `WRITE`

---

## Phase 4: Present the plan

Print a full summary table BEFORE writing anything. The developer must be able to review and say "go" or "stop":

```
Repos found: N
Will write:  N
Will skip:   N (already have AGENTS.md — use --overwrite to update these too)

┌─────────────────────────────────────────────────┬──────────────────────────┬──────────────────────────┬───────────┐
│ Repo                                            │ Stack                    │ Template                 │ Action    │
├─────────────────────────────────────────────────┼──────────────────────────┼──────────────────────────┼───────────┤
│ ~/projects/my-api                               │ TypeScript + Next.js     │ AGENTS.generic.md        │ WRITE     │
│ ~/projects/payment-service                      │ Python + security-sens.  │ AGENTS.security-first.md │ WRITE     │
│ ~/projects/old-app                              │ JavaScript               │ AGENTS.generic.md        │ SKIP ✓    │
│ ~/code/billing                                  │ .NET / C#                │ AGENTS.dotnet.md         │ WRITE     │
│ ~/code/scripts                                  │ Unknown                  │ AGENTS.generic.md        │ WRITE     │
└─────────────────────────────────────────────────┴──────────────────────────┴──────────────────────────┴───────────┘

Mode: DRY RUN — nothing written yet.
To apply: re-run with --write
To also update repos with existing AGENTS.md: re-run with --write --overwrite
To limit scope: re-run with --path ~/projects
```

If mode is `--write` or `--overwrite`, add:
```
Ready to write AGENTS.md to N repos. Type YES to proceed, or anything else to cancel.
```
Wait for the developer's explicit "YES" before proceeding. If the response is not "YES", stop and do nothing.

---

## Phase 5: Write the files (only if confirmed and --write or --overwrite)

For each repo with action = `WRITE` or `OVERWRITE`:

1. Read the assigned template from `~/.local/share/opencode-setup/templates/<template>` (or `$SETUP_DIR/templates/<template>` if the setup repo is elsewhere)

2. Do a **minimal fill-in** — replace the most important placeholders with what you know from the sniff:

   | Placeholder | Fill with |
   |---|---|
   | `<project-name>` | Directory name of the repo (basename of path) |
   | `<one-sentence description>` | `TODO: add a one-sentence description` |
   | Language line | Best guess from indicators (e.g., `TypeScript`, `Go`, `Python`) |
   | Framework line | Best guess from indicators, or `TODO:` if unknown |
   | Database line | `TODO: add database` (not enough info from sniff) |
   | Testing line | Best guess (vitest/jest for Node, pytest for Python, go test for Go), or `TODO:` |
   | All commands | `TODO: fill in project commands` |
   | Structure section | `TODO: describe project structure` |
   | `<prototype \| active development \| maintenance>` | `active development` (default assumption) |

   **Important**: leave clear `TODO:` markers for everything that couldn't be auto-detected. A partial AGENTS.md with clear gaps is better than a wrong one. The developer finishes it with `/setup-project` for full detection.

3. Add a header comment so the developer knows it was bulk-generated:
   ```markdown
   <!-- Generated by /init-all-repos on <date>. Run /setup-project for full stack detection. -->
   ```

4. Write to `<repo-path>/AGENTS.md`

5. Log each write:
   ```
   ✓ ~/projects/my-api/AGENTS.md  (TypeScript, generic template)
   ✓ ~/code/billing/AGENTS.md     (.NET, dotnet template)
   ✗ ~/projects/old-app           SKIPPED (existing AGENTS.md)
   ```

---

## Phase 6: Final report

```
Done.

Written: N repos
Skipped: N repos (existing AGENTS.md — run with --overwrite to update)
Errors:  N repos (list any failures)

Next steps for each repo:
  cd <repo> && opencode
  /setup-project      ← fills in the TODO: sections with full detection

Repos with security-sensitive templates (review these first):
  ~/projects/payment-service  →  AGENTS.security-first.md
  ...
```

---

## Notes on one-time use

This command is designed to be run **once** per machine to bootstrap all your existing repos. After the initial run:

- Use `/setup-project` when starting work in any specific repo — it does full detection and fills in all the details this command left as `TODO:`
- Re-run `/init-all-repos --path ~/new-projects` whenever you want to onboard a new batch
- The `--skip-existing` behavior (default) means re-running is safe — it won't touch repos you've already fully set up

The generated AGENTS.md files are starting points. Each one has `TODO:` markers showing exactly what needs to be filled in. Run `/setup-project` in a repo to promote it from "bulk initialized" to "fully configured."
