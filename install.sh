#!/usr/bin/env bash
#
# OpenCode Setup — smart incremental installer
#
# Detects what you already have installed and offers the right options.
# Safe to run multiple times — never overwrites your existing opencode.json.
#
# Usage:
#   ./install.sh              # interactive menu (recommended)
#   ./install.sh --skills     # non-interactive: just install commands/agents/skills
#   ./install.sh --update     # non-interactive: update existing commands/agents/skills
#   ./install.sh --full       # non-interactive: full setup including OpenCode + Ollama config
#

set -euo pipefail

# ─── Colour helpers ───────────────────────────────────────────────────────────
cyan()   { printf '\033[36m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n'  "$*"; }
step()   { echo; cyan "==> $*"; }
ok()     { green  "  [✓] $*"; }
warn()   { yellow "  [!] $*"; }
skip()   { printf '\033[2m  [–] %s\033[0m\n' "$*"; }

# ─── Locate repo root ─────────────────────────────────────────────────────────
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$SCRIPT_DIR"

# ─── OpenCode config paths (same on macOS and Linux) ─────────────────────────
CONFIG_DIR="$HOME/.config/opencode"
AUTH_DIR="$HOME/.local/share/opencode"

# ─── Detect current state ─────────────────────────────────────────────────────
has_opencode=false
has_config=false
has_commands=false
has_agents=false
has_skills=false

command -v opencode >/dev/null 2>&1            && has_opencode=true
[ -f "$CONFIG_DIR/opencode.json" ]             && has_config=true
[ -d "$CONFIG_DIR/command" ] && \
  ls "$CONFIG_DIR/command/"*.md >/dev/null 2>&1 && has_commands=true
[ -d "$CONFIG_DIR/agent" ] && \
  ls "$CONFIG_DIR/agent/"*.md >/dev/null 2>&1   && has_agents=true
[ -d "$CONFIG_DIR/skills" ] && \
  ls "$CONFIG_DIR/skills/"*.md >/dev/null 2>&1  && has_skills=true

# ─── Functions ────────────────────────────────────────────────────────────────

print_status() {
  echo
  bold "Current state"
  echo "─────────────────────────────────────────────────────"

  if $has_opencode; then
    ok "OpenCode installed  ($(command -v opencode))"
  else
    warn "OpenCode not found on PATH"
  fi

  if $has_config; then
    ok "opencode.json found — will not touch it"
  else
    warn "No opencode.json — provider not configured yet"
  fi

  echo
  if $has_commands; then
    ok "Commands installed  ($CONFIG_DIR/command/)"
  else
    warn "Commands not installed"
  fi

  if $has_agents; then
    ok "Agents installed    ($CONFIG_DIR/agent/)"
  else
    warn "Agents not installed"
  fi

  if $has_skills; then
    ok "Skills installed    ($CONFIG_DIR/skills/)"
  else
    warn "Skills not installed"
  fi

  echo "─────────────────────────────────────────────────────"
}

install_skills() {
  step "Installing commands, agents, and skills"

  mkdir -p "$CONFIG_DIR/command" "$CONFIG_DIR/agent" "$CONFIG_DIR/skills"

  cp -r "$REPO_ROOT/opencode/command/"* "$CONFIG_DIR/command/"
  ok "Commands  → $CONFIG_DIR/command/"

  cp -r "$REPO_ROOT/opencode/agent/"*   "$CONFIG_DIR/agent/"
  ok "Agents    → $CONFIG_DIR/agent/"

  cp -r "$REPO_ROOT/opencode/skills/"*  "$CONFIG_DIR/skills/"
  ok "Skills    → $CONFIG_DIR/skills/"
}

install_opencode() {
  step "Installing OpenCode"
  if $has_opencode; then
    skip "OpenCode already installed — skipping"
    return
  fi
  echo "  Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  # Try to pick up new PATH without opening a new shell
  # shellcheck disable=SC1091
  [ -f "$HOME/.zshrc"    ] && source "$HOME/.zshrc"    2>/dev/null || true
  # shellcheck disable=SC1091
  [ -f "$HOME/.bashrc"   ] && source "$HOME/.bashrc"   2>/dev/null || true
  # shellcheck disable=SC1091
  [ -f "$HOME/.profile"  ] && source "$HOME/.profile"  2>/dev/null || true
  if command -v opencode >/dev/null 2>&1; then
    ok "OpenCode installed"
  else
    warn "OpenCode installed but not on PATH in this shell — open a new terminal after setup"
  fi
}

configure_ollama() {
  step "Configuring Ollama provider"

  if $has_config; then
    skip "opencode.json already exists — skipping Ollama config"
    echo "      To reconfigure, edit $CONFIG_DIR/opencode.json manually."
    return
  fi

  ENV_FILE="$REPO_ROOT/config/env"
  EXAMPLE_FILE="$REPO_ROOT/config/env.example"

  if [ ! -f "$ENV_FILE" ]; then
    cp "$EXAMPLE_FILE" "$ENV_FILE"
  fi

  # shellcheck disable=SC1090
  source "$ENV_FILE"

  echo
  echo "  Current config: $OLLAMA_HOST:$OLLAMA_PORT  (model: $OLLAMA_MODEL)"
  read -rp "  Ollama server hostname or IP [${OLLAMA_HOST}]: " new_host
  if [ -n "$new_host" ]; then
    OLLAMA_HOST="$new_host"
    sed -i.bak "s|^OLLAMA_HOST=.*|OLLAMA_HOST=$new_host|" "$ENV_FILE"
    rm -f "${ENV_FILE}.bak"
  fi

  mkdir -p "$CONFIG_DIR" "$AUTH_DIR"

  sed -e "s|{{OLLAMA_HOST}}|$OLLAMA_HOST|g" \
      -e "s|{{OLLAMA_PORT}}|$OLLAMA_PORT|g" \
      -e "s|{{OLLAMA_MODEL}}|$OLLAMA_MODEL|g" \
      -e "s|{{OLLAMA_MODEL_DISPLAY}}|$OLLAMA_MODEL|g" \
      "$REPO_ROOT/config/opencode.json.template" > "$CONFIG_DIR/opencode.json"
  ok "Wrote $CONFIG_DIR/opencode.json"

  cp "$REPO_ROOT/config/auth.json" "$AUTH_DIR/auth.json"
  ok "Wrote $AUTH_DIR/auth.json"

  # Quick connection check
  echo
  SERVER_URL="http://$OLLAMA_HOST:$OLLAMA_PORT"
  if curl -s --max-time 5 "$SERVER_URL/api/tags" >/dev/null 2>&1; then
    ok "Reachable: $SERVER_URL"
  else
    warn "Could not reach $SERVER_URL — check server is running and hostname is correct"
  fi
}

print_next_steps() {
  echo
  bold "All done. What to do next:"
  echo
  echo "  1. Open any project in OpenCode:"
  echo "       cd ~/your-project && opencode"
  echo
  echo "  2. Onboard all your existing repos at once:"
  echo "       /init-all-repos"
  echo "     (dry-run by default — shows a plan, then run with --write to apply)"
  echo
  echo "  3. Fully configure a specific project:"
  echo "       /setup-project"
  echo "     (auto-detects stack from package.json / go.mod / *.csproj / etc.)"
  echo
  echo "  4. Before every code change:"
  echo "       /branch feat/my-feature   ← creates a branch, never touches main"
  echo "       /commit                   ← scans for secrets, commits, pushes"
  echo "       /pr                       ← creates a PR for your review, never merges"
  echo
}

# ─── Parse flags ──────────────────────────────────────────────────────────────
FLAG="${1:-}"

case "$FLAG" in
  --skills|-s)
    print_status
    install_skills
    print_next_steps
    exit 0
    ;;
  --update|-u)
    print_status
    install_skills
    ok "Commands, agents, and skills updated to latest version"
    print_next_steps
    exit 0
    ;;
  --full|-f)
    print_status
    install_opencode
    configure_ollama
    install_skills
    print_next_steps
    exit 0
    ;;
  --help|-h)
    echo "Usage: ./install.sh [option]"
    echo ""
    echo "  (no flag)    Interactive menu — detects your setup and offers the right options"
    echo "  --skills     Install commands/agents/skills only — safe for existing installs"
    echo "  --update     Update commands/agents/skills to latest (overwrites existing)"
    echo "  --full       Full setup: OpenCode + Ollama config + commands/agents/skills"
    echo "  --help       Show this help"
    exit 0
    ;;
  "")
    # Interactive mode — fall through to menu below
    ;;
  *)
    red "Unknown option: $FLAG"
    echo "Run ./install.sh --help for usage."
    exit 1
    ;;
esac

# ─── Interactive menu ─────────────────────────────────────────────────────────
echo
bold "OpenCode Setup"
echo "════════════════════════════════════════════════════════"

print_status

# Determine which menu to show based on detected state
echo

if $has_opencode && $has_config && ($has_commands && $has_agents && $has_skills); then
  # Everything installed — offer update only
  bold "Everything looks installed."
  echo
  echo "  1) Update commands, agents, and skills to latest version"
  echo "  q) Quit"
  echo
  read -rp "Choice [1]: " choice
  choice="${choice:-1}"
  case "$choice" in
    1) install_skills; ok "Updated to latest version" ;;
    q|Q) echo "Bye."; exit 0 ;;
    *) echo "No changes made."; exit 0 ;;
  esac

elif $has_opencode && $has_config; then
  # OpenCode + provider config exists, skills missing or partial
  bold "OpenCode and provider config detected."
  echo "  Your opencode.json will not be touched."
  echo
  echo "  1) Install commands, agents, and skills  (recommended)"
  echo "  2) Update commands, agents, and skills   (overwrites existing)"
  echo "  q) Quit"
  echo
  read -rp "Choice [1]: " choice
  choice="${choice:-1}"
  case "$choice" in
    1|2) install_skills ;;
    q|Q) echo "Bye."; exit 0 ;;
    *) echo "No changes made."; exit 0 ;;
  esac

elif $has_opencode && ! $has_config; then
  # OpenCode installed, no provider config
  bold "OpenCode is installed but no provider is configured."
  echo
  echo "  1) Configure Ollama connection + install commands/agents/skills"
  echo "  2) Install commands/agents/skills only  (you'll configure the provider yourself)"
  echo "  q) Quit"
  echo
  read -rp "Choice [1]: " choice
  choice="${choice:-1}"
  case "$choice" in
    1) configure_ollama; install_skills ;;
    2) install_skills ;;
    q|Q) echo "Bye."; exit 0 ;;
    *) echo "No changes made."; exit 0 ;;
  esac

else
  # OpenCode not installed
  bold "OpenCode not found."
  echo
  echo "  1) Full setup  — install OpenCode + configure Ollama + install commands/agents/skills"
  echo "  2) Skills only — install commands/agents/skills (you handle OpenCode and provider)"
  echo "  q) Quit"
  echo
  read -rp "Choice [1]: " choice
  choice="${choice:-1}"
  case "$choice" in
    1) install_opencode; configure_ollama; install_skills ;;
    2) install_skills ;;
    q|Q) echo "Bye."; exit 0 ;;
    *) echo "No changes made."; exit 0 ;;
  esac
fi

print_next_steps
