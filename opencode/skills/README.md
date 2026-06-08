# OpenCode Skills

Skills are reusable, composable instruction sets that can be embedded in your `AGENTS.md` or invoked inside a session. Unlike commands (which are invocable via `/command`) and agents (which run as separate AI instances), skills define **how** the AI thinks and operates in specific contexts.

## How to use

**In AGENTS.md**: Reference a skill to apply it globally for the project:
```
## AI Behavior
@opencode/skills/git-safety.md
@opencode/skills/test-first.md
```

**In a session**: Paste or load a skill inline when you need it for a specific task:
```
@path/to/opencode/skills/performance.md
Now analyze this function for performance issues.
```

**In a command**: Load a skill at the top of a command file:
```
@opencode/skills/hermetic-tests.md
Generate integration tests for $ARGUMENTS
```

## Available skills

| Skill | Purpose |
|---|---|
| `git-safety.md` | Branch protection, commit hygiene, PR workflow rules |
| `test-first.md` | TDD discipline — tests before code, refactor after green |
| `hermetic-tests.md` | Rules for writing fully isolated, deterministic tests |
| `security-mindset.md` | Threat-modeling lens applied to every code change |
| `performance.md` | Systematic performance analysis and optimization discipline |
| `api-design.md` | Consistent, versioned, documented API conventions |
| `code-review-lens.md` | Structured review framework for reading others' code |

## Writing a skill

A skill is a markdown file with:
1. A short header explaining what mindset/mode it activates
2. A set of numbered or bulleted rules — specific, actionable, not vague
3. Optionally: examples of DO vs DO NOT

Keep skills focused — one skill = one concern. Compose them rather than building monolithic ones.
