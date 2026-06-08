# Architecture

How the pieces fit together.

## The two-tier model

This setup separates **where the model runs** from **where you work**.

```
┌─────────────────────────────────────┐
│  SERVER                             │
│  (the GPU machine)                  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Ollama                       │  │
│  │  - Model: qwen3-coder:30b     │  │
│  │  - Listening on :11434        │  │
│  │  - 32K context                │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Tailscale (optional)         │  │
│  │  - Exposes server on tailnet  │  │
│  └───────────────────────────────┘  │
└──────────────┬──────────────────────┘
               │
               │  HTTP :11434
               │  (LAN or Tailscale)
               │
┌──────────────┴──────────────────────┐
│  CLIENT(S)                          │
│  (any machine you type on)          │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  OpenCode                     │  │
│  │  - TUI in terminal            │  │
│  │  - Plan / Build modes         │  │
│  │  - Commands and subagents     │  │
│  │  - Reads project AGENTS.md    │  │
│  └───────────────────────────────┘  │
│                                     │
│  Your code project goes here.       │
│  cd into it, run `opencode`.        │
└─────────────────────────────────────┘
```

## Why split it this way

**Models are heavy.** A 30B model wants 16-20GB of memory and dedicated GPU time. Your gaming laptop has that. Your work MacBook Air does not.

**Coding happens everywhere.** You want to use the same setup at the desk, on the couch, at the office, on a phone tether. All of those are network problems, not "buy more GPUs" problems.

**One server, many clients.** Configure the model once. Connect from anywhere. Same agents, same commands, same conventions.

## How a request flows

1. You type a prompt in OpenCode on your client.
2. OpenCode resolves your project's `AGENTS.md`, loads your active commands/agents, and assembles the full prompt with file context.
3. OpenCode sends an HTTP request to `http://gpu-rig:11434/v1/chat/completions`.
4. Tailscale (or your LAN) routes the packets to the server.
5. Ollama on the server receives the request, runs inference on the GPU, streams tokens back.
6. OpenCode parses the streaming response, executes any tool calls (file reads, edits, bash commands) **locally on your client**, and continues the loop.

**Key insight**: tool calls execute on the client, not the server. The model decides what to do; your local OpenCode does it. The server is stateless inference.

## Why each piece matters

### Ollama (server)

The model server. Loads weights into GPU memory and serves an HTTP API compatible with OpenAI's chat completions format. We configure it to listen on all network interfaces with a 32K context.

### OpenCode (client)

The agent. Wraps the model with a tool-use loop (read files, edit files, run commands), a TUI, and a project configuration system. Knows nothing about GPUs; just sends HTTP requests.

### Tailscale (transport)

A mesh VPN. Both your server and your clients install it and sign in to the same account. They get stable private IPs and friendly hostnames that work from anywhere — coffee shop, office, hotel.

Alternative for LAN-only use: just use the server's local IP directly. No Tailscale needed.

### AGENTS.md (project conventions)

A markdown file in your project root that tells the agent how to work in this codebase: tech stack, conventions, rules, what to do, what not to do. Read on every session. Halves your prompt overhead.

### Commands (reusable prompts)

`.opencode/command/foo.md` in your project (or `~/.config/opencode/command/foo.md` globally). Type `/foo` to invoke. Used for: any prompt you'd write twice.

### Subagents (specialized roles)

`.opencode/agent/bar.md`. Invoke with `@bar` or `/agent bar`. Used for: tasks that need a different system prompt or restricted tools (code review, debugging, doc writing).

## Failure modes and how the system handles them

**Server goes down.** Client gets connection errors. Fix: restart Ollama or check Tailscale.

**Model not loaded.** Client gets "model not found." Fix: `ollama pull <model>` on the server.

**Context overflow.** Conversation fills the 32K window; quality degrades. Fix: `/compact` periodically.

**Tool call timeout.** Local file ops hang. Fix: restart OpenCode; the model lost track of the conversation state.

**Tailscale drops.** Connection lags or fails. Fix: `tailscale netcheck` to diagnose; sometimes a sleep/wake fixes it.

**Power loss at the server.** Sessions die. The fix is "make sure your server stays up" — UPS, persistent power, sleep disabled.
