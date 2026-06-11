# OpenCode Workflow

A portable, opinionated setup for running [OpenCode](https://opencode.ai) against a self-hosted Ollama server with any local coding model (Qwen3-Coder, DeepSeek, Codestral, etc.).

Run a powerful model on one machine. Access it from anywhere — Mac, Linux, Windows — over a private Tailscale mesh. Same agent config, custom commands, subagents, and project conventions everywhere.

## Architecture

```
┌─────────────────────────────┐         ┌─────────────────────────────┐
│   SERVER (one machine)      │         │   CLIENT (any machine)      │
│                             │         │                             │
│   • Ollama                  │ ◄────── │   • OpenCode TUI            │
│   • Model: qwen3-coder:30b  │  HTTP   │   • Custom commands         │
│   • GPU + sufficient RAM    │ :11434  │   • Subagents               │
│   • Tailscale (or LAN)      │         │   • Tailscale               │
└─────────────────────────────┘         └─────────────────────────────┘
```

**Server**: Whatever has the most GPU power. Typically a desktop or gaming laptop. Runs Ollama and serves the model over HTTP.

**Client**: Whatever you want to type on. Mac, Linux laptop, Windows machine. Runs the OpenCode TUI and connects to the server over the network (LAN or Tailscale).

The same machine can be both. For solo desktop use, server and client are localhost. For remote access, separate machines connected via Tailscale.

## Quick start

### Already have OpenCode running? Just add the skills

If you already have OpenCode working (with Ollama, Claude, or any other provider), this is all you need on your client machine:

**macOS / Linux:**
```bash
git clone https://github.com/hardcodeddev/opencode-setup.git ~/opencode-setup
cd ~/opencode-setup
./install.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/hardcodeddev/opencode-setup.git $HOME\opencode-setup
cd $HOME\opencode-setup
.\install.ps1
```

The installer detects what you already have and shows you only the relevant options. It **never overwrites your existing `opencode.json`**. For an existing Ollama + OpenCode setup just pick option 1 — it copies the commands/agents/skills and leaves everything else untouched.

To update later:
```bash
cd ~/opencode-setup && git pull && ./install.sh --update
```

---

### Ollama already on this machine — just add OpenCode and skills

If you're developing directly on the machine that runs Ollama (no remote server needed):

**macOS / Linux:**
```bash
git clone https://github.com/hardcodeddev/opencode-setup.git ~/opencode-setup
cd ~/opencode-setup
./setup/client/local-dev.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/hardcodeddev/opencode-setup.git $HOME\opencode-setup
cd $HOME\opencode-setup
.\setup\client\local-dev.ps1
```

The script checks Ollama is running, lists your available models so you can pick one, installs OpenCode if missing, writes a `localhost` config, and copies all commands/agents/skills. Skips Tailscale entirely since you're already local.

---

### Full setup from scratch

### 1. Set up the server (run once)

On the machine with the GPU:

**Windows:**
```powershell
git clone https://github.com/hardcodeddev/opencode-setup.git
cd opencode-setup
.\setup\server\windows.ps1
```

**macOS:**
```bash
git clone https://github.com/hardcodeddev/opencode-setup.git
cd opencode-setup
./setup/server/mac.sh
```

**Linux:**
```bash
git clone https://github.com/hardcodeddev/opencode-setup.git
cd opencode-setup
./setup/server/linux.sh
```

The setup script will:
- Install Ollama (if not already installed)
- Pull your chosen model
- Configure Ollama to accept network connections
- Open the firewall on port 11434
- Build a context-tuned model variant
- Optionally install Tailscale for remote access

### 2. Set up each client

On every machine you want to code from:

**Windows:**
```powershell
git clone https://github.com/hardcodeddev/opencode-setup.git
cd opencode-setup
.\setup\client\windows.ps1
```

**macOS:**
```bash
git clone https://github.com/hardcodeddev/opencode-setup.git
cd opencode-setup
./setup/client/mac.sh
```

**Linux:**
```bash
git clone https://github.com/hardcodeddev/opencode-setup.git
cd opencode-setup
./setup/client/linux.sh
```

You'll be prompted for the server hostname (Tailscale name like `gpu-rig`, a LAN IP, or `localhost`). The script will write the OpenCode config files and validate the connection.

### 3. Drop into a project and code

```bash
cd ~/your-project
opencode
```

Press `Tab` to toggle Plan/Build mode. See [docs/workflow-guide.md](docs/workflow-guide.md) for daily-use tips.

## Customization

Edit `config/env` (created from `config/env.example` on first run) to set your defaults:

```bash
OLLAMA_HOST=gpu-rig          # Tailscale name, LAN IP, or localhost
OLLAMA_PORT=11434
OLLAMA_MODEL=qwen3-coder:30b
OLLAMA_CONTEXT_LENGTH=32768
```

Setup scripts read this file to template the OpenCode config and Ollama variant.

## What's in this repo

```
opencode-setup/
├── README.md                        # You are here
├── install.sh                       # Smart installer for macOS/Linux (start here)
├── install.ps1                      # Smart installer for Windows (start here)
├── LICENSE
├── .gitignore
├── setup/
│   ├── server/                      # Server setup scripts (one per OS)
│   └── client/                      # Client setup scripts (one per OS)
├── config/
│   ├── opencode.json.template       # OpenCode config (templated)
│   ├── auth.json                    # Required placeholder for Ollama
│   ├── Modelfile                    # Ollama context-tuning Modelfile
│   └── env.example                  # User config template
├── opencode/
│   ├── command/                     # Reusable slash commands
│   │   ├── init-all-repos.md        # /init-all-repos — one-time bulk init for all repos on machine
│   │   ├── setup-project.md         # /setup-project — bootstrap any project from scratch
│   │   ├── branch.md                # /branch — create feature branch, never touches main
│   │   ├── commit.md                # /commit — atomic commit with secret scanning
│   │   ├── pr.md                    # /pr — create PR, never merges it
│   │   ├── integrate-test.md        # /integrate-test — hermetic integration tests
│   │   ├── security.md              # /security — full security audit
│   │   ├── refactor.md              # /refactor — safe refactor with test-first
│   │   ├── test.md                  # /test — unit test generation
│   │   ├── review.md                # /review — code review with severity
│   │   └── plan.md                  # /plan — implementation planning (no code)
│   ├── agent/                       # Subagents (invoke with @name)
│   │   ├── git-guardian.md          # @git-guardian — enforces branch safety
│   │   ├── integration-tester.md    # @integration-tester — hermetic test specialist
│   │   ├── security-auditor.md      # @security-auditor — read-only security review
│   │   ├── code-reviewer.md         # @code-reviewer — read-only code reviewer
│   │   └── debugger.md              # @debugger — hypothesis-driven debugging
│   └── skills/                      # Composable instruction sets for AGENTS.md
│       ├── git-safety.md            # Branch protection rules
│       ├── test-first.md            # TDD discipline
│       ├── hermetic-tests.md        # Self-contained test patterns
│       ├── security-mindset.md      # Threat-model lens for every change
│       ├── performance.md           # Performance analysis discipline
│       └── code-review-lens.md      # Structured review framework
├── templates/
│   ├── AGENTS.generic.md            # Generic project template (with git safety + hermetic tests)
│   ├── AGENTS.security-first.md     # Security-sensitive project template
│   └── AGENTS.dotnet.md             # .NET / C# project template
└── docs/
    ├── architecture.md              # How the system fits together
    ├── workflow-guide.md            # Daily-use patterns
    ├── troubleshooting.md           # Common issues & fixes
    └── learning-path.md             # 2-week skill-building plan
```

## Commands reference

| Command | What it does |
|---|---|
| `/init-all-repos [flags]` | **One-time bulk init** — scans all repos on the machine, detects each stack, writes tailored `AGENTS.md` to every repo. Use once to onboard your whole machine. |
| `/setup-project [stack]` | **Per-project bootstrap** — clones this repo if missing, installs all commands/agents/skills, fully detects your stack, generates a complete `AGENTS.md` |
| `/branch` | Creates a feature branch from main — **never touches main directly** |
| `/commit` | Stages, scans for secrets, commits with conventional message, pushes to feature branch |
| `/pr` | Creates a PR for your review — **never merges it** |
| `/integrate-test` | Generates hermetic integration tests (no real external dependencies) |
| `/security` | Full security audit: injection, auth, secrets, crypto, XSS, CSRF |
| `/refactor` | Safe refactor — writes tests first, changes structure without changing behavior |
| `/review` | Code review with CRITICAL/HIGH/MEDIUM/LOW severity ratings |
| `/plan` | Implementation plan with no code written — for scoping and review |
| `/test` | Unit test generation matching your project's test conventions |

### Onboard a single new project

```bash
cd ~/your-project
opencode
# then type:
/setup-project
# or with a stack hint:
/setup-project typescript next.js postgresql
/setup-project python fastapi redis security
/setup-project dotnet asp.net-core sqlserver
```

`/setup-project` clones this repo if not already installed, syncs all commands/agents/skills into your OpenCode config, detects your stack from `package.json` / `go.mod` / `*.csproj` / etc., and writes a tailored `AGENTS.md` to the project root.

### Onboard all your existing repos at once

Run this once from any project to bulk-initialize your whole machine:

```bash
opencode
# then type:
/init-all-repos              # dry-run first — shows the plan, writes nothing
/init-all-repos --write      # apply to all repos missing an AGENTS.md
/init-all-repos --write --overwrite   # also update repos that already have one
/init-all-repos --path ~/projects     # scope to a specific directory
```

`/init-all-repos` scans common developer directories (`~/projects`, `~/code`, `~/dev`, etc.), fast-sniffs each repo's root files to detect the stack, picks the right template (generic, security-first, or dotnet), shows you a full plan table, waits for your `YES`, then writes. Repos it can't fully detect get a template with clear `TODO:` markers — run `/setup-project` in those repos to fill in the details.

## Subagents reference

Invoke with `@agent-name` or `/agent agent-name` in OpenCode:

| Agent | What it does |
|---|---|
| `@git-guardian` | Handles git ops safely — enforces branch protection, scans commits for secrets |
| `@integration-tester` | Writes hermetic integration tests — no real DB, HTTP, or filesystem |
| `@security-auditor` | Deep read-only security review with file:line references |
| `@code-reviewer` | Read-only senior code review across correctness, security, and maintainability |
| `@debugger` | Hypothesis-driven root cause analysis — no symptom patching |

## Skills reference

Skills are composable rules you embed in your project's `AGENTS.md` or load inline:

| Skill | Load in AGENTS.md |
|---|---|
| Git safety | `@opencode/skills/git-safety.md` |
| Test-first (TDD) | `@opencode/skills/test-first.md` |
| Hermetic tests | `@opencode/skills/hermetic-tests.md` |
| Security mindset | `@opencode/skills/security-mindset.md` |
| Performance analysis | `@opencode/skills/performance.md` |
| Code review lens | `@opencode/skills/code-review-lens.md` |

## Git safety guarantees

The AI is configured never to:
- Push to `main` or `master`
- Merge a pull request
- Force-push to shared branches
- Commit secrets or credentials
- Skip commit hooks with `--no-verify`

It will always:
- Create a named feature branch before making changes
- Scan diffs for secrets before staging
- Use conventional commit messages
- Push to the feature branch and report the PR URL for your review

## Project templates

Copy the right template into your project as `AGENTS.md`:

```bash
# Any project
cp templates/AGENTS.generic.md ~/your-project/AGENTS.md

# Security-sensitive (auth, payments, healthcare, PII)
cp templates/AGENTS.security-first.md ~/your-project/AGENTS.md

# .NET / C#
cp templates/AGENTS.dotnet.md ~/your-project/AGENTS.md
```

Each template includes the git safety rules, hermetic testing protocols, and a security baseline baked in.

## Prerequisites

- **Server**: A machine with at least 8GB VRAM (NVIDIA preferred), or 16GB+ unified memory on Apple Silicon. More is better.
- **Client**: Anything that can run a terminal.
- **Both**: Tailscale account (free tier is plenty) if you want remote access. Skip if LAN-only.

## Recommended models by hardware

| VRAM       | Recommended model                | Notes                                  |
|------------|----------------------------------|----------------------------------------|
| 6-8 GB     | `qwen2.5-coder:7b`               | Fast, autocomplete tier                |
| 8-12 GB    | `qwen2.5-coder:14b`              | Sweet spot for daily use               |
| 12-16 GB   | `qwen2.5-coder:32b` (Q4)         | Excellent quality                      |
| 16+ GB     | `qwen3-coder:30b` (MoE)          | Best agentic performance               |
| 24+ GB     | `qwen3-coder-next` or larger     | Closest to frontier                    |

Apple Silicon: unified memory acts as VRAM. M2/M3/M4 with 16GB+ runs the 30B comfortably.

## License

MIT. Use it, fork it, share it. See [LICENSE](LICENSE).

## Contributing

This is a personal workflow setup, but improvements via PRs are welcome. Especially:
- Setup scripts for other distros (Arch, Fedora)
- Additional subagents or commands for specific workflows
- Project AGENTS.md templates for other stacks (Rust, Go, TypeScript, Python)
- Additional skills for specialized contexts (docs-writing, API design, data engineering)

## Acknowledgements

- [OpenCode](https://opencode.ai) — The agent framework
- [Ollama](https://ollama.com) — The local model server
- [Tailscale](https://tailscale.com) — The mesh VPN that makes this practical
- Resource curation drawn from [opencodex.cc](https://opencodex.cc), [Sudipta Pathak's OpenCode guide](https://sudiptapathak.com/blog/opencode-guide/), and the community repos linked in `docs/learning-path.md`.
