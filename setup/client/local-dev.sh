#!/usr/bin/env bash
#
# Local dev setup — for machines that already have Ollama and Tailscale.
# Installs OpenCode and the skills/commands/agents. Points config to localhost.
#
# Usage: ./setup/client/local-dev.sh
#

set -euo pipefail

cyan()  { printf '\033[36m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }
step()  { echo; cyan "==> $*"; }
ok()    { green "  [✓] $*"; }
warn()  { yellow "  [!] $*"; }

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
CONFIG_DIR="$HOME/.config/opencode"
AUTH_DIR="$HOME/.local/share/opencode"

# ── 1. Verify Ollama is running ───────────────────────────────────────────────
step "Checking Ollama"
if ! curl -s --max-time 3 http://localhost:11434/api/tags >/dev/null 2>&1; then
  warn "Ollama isn't responding on localhost:11434"
  echo "  Start it with: ollama serve"
  echo "  Then re-run this script."
  exit 1
fi
ok "Ollama is running"

# ── 2. Pick a model ───────────────────────────────────────────────────────────
step "Available models"
MODELS_JSON="$(curl -s http://localhost:11434/api/tags)"
MODELS="$(echo "$MODELS_JSON" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)"

if [ -z "$MODELS" ]; then
  warn "No models found. Pull one first: ollama pull qwen3-coder:30b"
  exit 1
fi

echo "$MODELS" | nl -w2 -s') '
echo
read -rp "  Choose model number [1]: " model_num
model_num="${model_num:-1}"
CHOSEN_MODEL="$(echo "$MODELS" | sed -n "${model_num}p")"

if [ -z "$CHOSEN_MODEL" ]; then
  warn "Invalid selection"
  exit 1
fi
ok "Using model: $CHOSEN_MODEL"

# ── 3. Install OpenCode ───────────────────────────────────────────────────────
step "Checking OpenCode"
if command -v opencode >/dev/null 2>&1; then
  ok "OpenCode already installed ($(command -v opencode))"
else
  echo "  Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  # shellcheck disable=SC1091
  [ -f "$HOME/.zshrc"   ] && source "$HOME/.zshrc"   2>/dev/null || true
  # shellcheck disable=SC1091
  [ -f "$HOME/.bashrc"  ] && source "$HOME/.bashrc"  2>/dev/null || true
  if command -v opencode >/dev/null 2>&1; then
    ok "OpenCode installed"
  else
    warn "OpenCode installed but not on PATH yet — open a new terminal after this finishes"
  fi
fi

# ── 4. Write config ───────────────────────────────────────────────────────────
step "Writing OpenCode config"
mkdir -p "$CONFIG_DIR" "$AUTH_DIR"

if [ -f "$CONFIG_DIR/opencode.json" ]; then
  cp "$CONFIG_DIR/opencode.json" "$CONFIG_DIR/opencode.json.bak"
  warn "Existing opencode.json backed up to opencode.json.bak"
fi

cat > "$CONFIG_DIR/opencode.json" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "$CHOSEN_MODEL": {
          "name": "$CHOSEN_MODEL",
          "tools": true
        }
      }
    }
  },
  "model": "ollama/$CHOSEN_MODEL"
}
EOF
ok "Wrote $CONFIG_DIR/opencode.json  (model: $CHOSEN_MODEL, host: localhost)"

cp "$REPO_ROOT/config/auth.json" "$AUTH_DIR/auth.json"

# ── 5. Install commands / agents / skills ─────────────────────────────────────
step "Installing commands, agents, and skills"

mkdir -p "$CONFIG_DIR/command" "$CONFIG_DIR/agent" "$CONFIG_DIR/skills"
cp -r "$REPO_ROOT/opencode/command/"* "$CONFIG_DIR/command/"
ok "Commands  → $CONFIG_DIR/command/"
cp -r "$REPO_ROOT/opencode/agent/"*   "$CONFIG_DIR/agent/"
ok "Agents    → $CONFIG_DIR/agent/"
cp -r "$REPO_ROOT/opencode/skills/"*  "$CONFIG_DIR/skills/"
ok "Skills    → $CONFIG_DIR/skills/"

# ── Done ──────────────────────────────────────────────────────────────────────
echo
green "════════════════════════════════════"
green "  Done"
green "════════════════════════════════════"
echo
echo "  Model:  $CHOSEN_MODEL  (localhost)"
echo
echo "  Start coding:"
echo "    cd ~/your-project && opencode"
echo
echo "  First time in a project:"
echo "    /setup-project"
echo
echo "  Onboard all existing repos:"
echo "    /init-all-repos"
echo
