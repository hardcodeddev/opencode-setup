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

### 1. Set up the server (run once)

On the machine with the GPU:

**Windows:**
```powershell
git clone https://github.com/<your-username>/opencode-workflow.git
cd opencode-workflow
.\setup\server\windows.ps1
```

**macOS:**
```bash
git clone https://github.com/<your-username>/opencode-workflow.git
cd opencode-workflow
./setup/server/mac.sh
```

**Linux:**
```bash
git clone https://github.com/<your-username>/opencode-workflow.git
cd opencode-workflow
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
git clone https://github.com/<your-username>/opencode-workflow.git
cd opencode-workflow
.\setup\client\windows.ps1
```

**macOS:**
```bash
git clone https://github.com/<your-username>/opencode-workflow.git
cd opencode-workflow
./setup/client/mac.sh
```

**Linux:**
```bash
git clone https://github.com/<your-username>/opencode-workflow.git
cd opencode-workflow
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
opencode-workflow/
├── README.md                    # You are here
├── LICENSE
├── .gitignore
├── setup/
│   ├── server/                  # Server setup scripts (one per OS)
│   └── client/                  # Client setup scripts (one per OS)
├── config/
│   ├── opencode.json.template   # OpenCode config (templated)
│   ├── auth.json                # Required placeholder for Ollama
│   ├── Modelfile                # Ollama context-tuning Modelfile
│   └── env.example              # User config template
├── opencode/
│   ├── command/                 # Reusable slash commands
│   └── agent/                   # Subagents (code-reviewer, etc.)
├── templates/
│   ├── AGENTS.dotnet.md         # .NET / C# project template
│   └── AGENTS.generic.md        # Generic project template
└── docs/
    ├── architecture.md          # How the system fits together
    ├── workflow-guide.md        # Daily-use patterns
    ├── troubleshooting.md       # Common issues & fixes
    └── learning-path.md         # 2-week skill-building plan
```

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
- Additional subagents (`@security-review`, `@docs-writer`, etc.)
- Project AGENTS.md templates for other stacks (Rust, Go, TypeScript, Python)

## Acknowledgements

- [OpenCode](https://opencode.ai) — The agent framework
- [Ollama](https://ollama.com) — The local model server
- [Tailscale](https://tailscale.com) — The mesh VPN that makes this practical
- Resource curation drawn from [opencodex.cc](https://opencodex.cc), [Sudipta Pathak's OpenCode guide](https://sudiptapathak.com/blog/opencode-guide/), and the community repos linked in `docs/learning-path.md`.
