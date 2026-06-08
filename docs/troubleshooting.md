# Troubleshooting

Common issues and fixes, in rough order of how often you'll hit them.

## OpenCode shows help text then exits

**Cause**: No provider configured or no auth.json placeholder.

**Fix**: Re-run the client setup script. It writes both files. If you're configuring manually, you need BOTH:
- `~/.config/opencode/opencode.json` (provider config)
- `~/.local/share/opencode/auth.json` (auth placeholder — even for Ollama which doesn't need auth)

## "Model not found" error

**Cause**: The model name in your client config doesn't match a model installed on the server.

**Fix**:
```bash
# On the server
ollama list
```
Match the name exactly in your client config. Remember that `qwen3-coder:30b` and `qwen3-coder:30b-tuned` are different models.

## Responses are slow / first token takes 30+ seconds

**Causes** (in order of likelihood):

1. **Model is cold-loading**. First request after the server sleeps loads the model into VRAM. Subsequent requests are fast. Fix: set `OLLAMA_KEEP_ALIVE=60m` so it stays loaded.
2. **GPU offload is too low**. Model is mostly running on CPU. Check `ollama ps` on the server — if it shows the model running with less than 50% GPU, you need to bump `num_gpu` in a Modelfile.
3. **Thermal throttling**. Laptop GPUs throttle hard under sustained load. Make sure it's plugged in and consider a cooling pad.
4. **Tailscale on DERP relay** instead of direct connection. Run `tailscale netcheck` on the client — if you see "DERP" instead of "direct" and you're on a fast network, that's adding latency.

## Tool calls fail or hang mid-task

**Cause**: Context window is too small. Default Ollama context is 2048 tokens, which doesn't fit the tool-call protocol.

**Fix**: Set `OLLAMA_CONTEXT_LENGTH=32768` system-wide on the server, OR use the `-tuned` model variant the setup script created:

```bash
# In your client opencode.json, change the model name to:
# qwen3-coder:30b-tuned
```

Verify with `ollama ps` — the context column should show 32768 (or whatever you set).

## "Could not connect to host" from client

**Diagnostic sequence**:

```bash
# 1. Is the server reachable at all?
ping gpu-rig   # or whatever your hostname is

# 2. Is Tailscale up on both ends?
tailscale status

# 3. Is Ollama listening on the network (not just localhost)?
# From the server itself:
curl http://localhost:11434/api/tags     # should work
# From the client:
curl http://gpu-rig:11434/api/tags       # should also work

# 4. Is the server's firewall blocking?
# Windows server:
Get-NetFirewallRule -DisplayName "Ollama*"
# Linux server:
sudo ufw status  # or firewall-cmd --list-all
```

If step 3 works from the server but not the client, it's a firewall or network routing issue. If it doesn't work even from the server, Ollama isn't listening on all interfaces — check `OLLAMA_HOST=0.0.0.0:11434`.

## "OLLAMA_HOST" environment variable not taking effect (Windows)

**Cause**: `setx` sets the variable but it doesn't apply to the current Ollama session.

**Fix**:
1. Use `setx /M` (with admin) to set system-wide.
2. After setting, fully quit Ollama (right-click system tray → Quit, NOT just close window).
3. Sign out and back in, or reboot. Env vars only apply to new sessions.
4. Verify with `netstat -an | findstr 11434` — should show `0.0.0.0:11434`, not `127.0.0.1:11434`.

## OpenCode install on Windows fails with npm

**Cause**: Known issue with the npm wrapper script on Windows. The `/bin/sh.exe` path doesn't exist.

**Fix**: Use Scoop instead:
```powershell
scoop bucket add extras
scoop install extras/opencode
```

The client setup script in this repo does this automatically.

## OpenCode UI looks broken / doesn't render

**Cause**: Terminal can't render the TUI.

**Fix**:
- **Windows**: Use Windows Terminal (from Microsoft Store), not cmd.exe or PowerShell ISE.
- **Mac**: Default Terminal.app works, iTerm2 also works.
- **Linux**: Most modern terminals work (gnome-terminal, kitty, alacritty, wezterm).

PowerShell ISE specifically is known to be broken. Windows Terminal solves it.

## Model gives weird/wrong/incomplete answers

**Causes**:

1. **Context full**. Type `/tokens` — if you're past 70%, that's the issue. Run `/compact`.
2. **Prompt too vague**. Local models need more explicit prompts than Claude. Be specific about file paths, what you want, what to avoid.
3. **Missing AGENTS.md**. The model doesn't know your conventions. Drop a template in.
4. **Model is wrong fit for task**. Some models are stronger at certain tasks. Try a different one.

## Tailscale connection drops during a session

**Cause**: Network change, sleep/wake on either end, or DERP relay issue.

**Fix**:
- `tailscale status` to check
- `tailscale up` to force reconnect
- If your home network changed IP, Tailscale will eventually reconcile. Force it with sleep/wake of the Tailscale daemon.

## Gaming laptop overheats during long sessions

**Symptoms**: Tokens-per-second drops over time. Loud fans. Maybe thermal shutdown.

**Fixes**:
- Cooling pad. Underrated.
- Make sure it's on a hard surface, not a blanket.
- Limit power profile (paradoxically, capping at ~80% TDP often keeps clocks higher long-term than full-bore-then-throttle).
- Undervolt the GPU if you're comfortable doing so.

## Sessions die when the laptop sleeps

**Fix on Windows server**:
```powershell
powercfg /change standby-timeout-ac 0
```
On battery: it's a laptop, just keep it plugged in.

## "Out of memory" errors on the server

**Cause**: Model + KV cache + your other apps exceed VRAM + system RAM.

**Fixes**:
1. Close other applications on the server.
2. Reduce context length in `config/env` (try 16384 instead of 32768).
3. Use a smaller model (qwen2.5-coder:14b instead of qwen3-coder:30b).
4. Enable flash attention if you haven't: `OLLAMA_FLASH_ATTENTION=1`.
5. Quantize the KV cache: `OLLAMA_KV_CACHE_TYPE=q8_0`.

The setup scripts set the last two automatically.

## Subagents don't load

**Cause**: Wrong location, missing frontmatter, or syntax error.

**Fix**:
- Subagents go in `~/.config/opencode/agent/` (global) or `.opencode/agent/` (project).
- Each must have YAML frontmatter at the top: `---\ndescription: ...\n---`.
- Filenames become the agent name. `code-reviewer.md` → `@code-reviewer`.

## When all else fails

```bash
# Verbose mode - shows everything OpenCode is doing
opencode --verbose

# Single-shot mode - lets you see the actual error instead of TUI eating it
opencode run "hello"
```

The `opencode run` mode prints errors directly. Use it to debug config issues.

If you're really stuck, the OpenCode community Discord is active and helpful. Link: [opencode.ai](https://opencode.ai).
