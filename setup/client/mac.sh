#!/usr/bin/env bash
#
# Sets up an OpenCode client on macOS.
#
# This script will:
#   - Install OpenCode (if not already present)
#   - Prompt for the Ollama server hostname
#   - Write OpenCode config files (opencode.json, auth.json)
#   - Install agents and commands from this repo
#   - Validate the connection
#

set -euo pipefail

# ----- Helpers -----
cyan() { printf '\033[36m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red() { printf '\033[31m%s\033[0m\n' "$*"; }
step() { echo; cyan "==> $*"; }
ok() { green "[OK] $*"; }
warn() { yellow "[WARN] $*"; }
err() { red "[ERROR] $*"; }

# ----- Locate repo root -----
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
ENV_FILE="$REPO_ROOT/config/env"
EXAMPLE_FILE="$REPO_ROOT/config/env.example"

# ----- Initialize config -----
if [ ! -f "$ENV_FILE" ]; then
    step "Initializing configuration"
    cp "$EXAMPLE_FILE" "$ENV_FILE"
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

# ----- Prompt for server hostname if default -----
echo ""
echo "Current server config: $OLLAMA_HOST:$OLLAMA_PORT (model: $OLLAMA_MODEL)"
read -rp "Press Enter to keep, or type a new hostname/IP (e.g., gpu-rig, 192.168.1.50, localhost): " new_host
if [ -n "$new_host" ]; then
    OLLAMA_HOST="$new_host"
    # Update the env file
    sed -i.bak "s|^OLLAMA_HOST=.*|OLLAMA_HOST=$new_host|" "$ENV_FILE"
    rm -f "${ENV_FILE}.bak"
    ok "Updated config/env"
fi

# ----- Install OpenCode -----
step "Checking for OpenCode"
if command -v opencode >/dev/null 2>&1; then
    ok "OpenCode already installed: $(command -v opencode)"
else
    echo "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
    # Source profile so 'opencode' is available in this session
    # shellcheck disable=SC1091
    [ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc" || true
    # shellcheck disable=SC1091
    [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" || true
    if ! command -v opencode >/dev/null 2>&1; then
        warn "OpenCode installed but not on PATH in this shell. Open a new terminal after this script finishes."
    else
        ok "OpenCode installed"
    fi
fi

# ----- Write OpenCode config -----
step "Writing OpenCode config"

CONFIG_DIR="$HOME/.config/opencode"
AUTH_DIR="$HOME/.local/share/opencode"
mkdir -p "$CONFIG_DIR" "$AUTH_DIR"

# Generate opencode.json from template
sed -e "s|{{OLLAMA_HOST}}|$OLLAMA_HOST|g" \
    -e "s|{{OLLAMA_PORT}}|$OLLAMA_PORT|g" \
    -e "s|{{OLLAMA_MODEL}}|$OLLAMA_MODEL|g" \
    -e "s|{{OLLAMA_MODEL_DISPLAY}}|$OLLAMA_MODEL|g" \
    "$REPO_ROOT/config/opencode.json.template" > "$CONFIG_DIR/opencode.json"

ok "Wrote $CONFIG_DIR/opencode.json"

# Copy auth.json placeholder (Ollama doesn't need real auth)
cp "$REPO_ROOT/config/auth.json" "$AUTH_DIR/auth.json"
ok "Wrote $AUTH_DIR/auth.json"

# ----- Install commands and agents -----
step "Installing OpenCode commands and agents"

if [ -d "$REPO_ROOT/opencode/command" ] && [ "$(ls -A "$REPO_ROOT/opencode/command")" ]; then
    mkdir -p "$CONFIG_DIR/command"
    cp -r "$REPO_ROOT/opencode/command/"* "$CONFIG_DIR/command/" 2>/dev/null || true
    ok "Installed commands to $CONFIG_DIR/command/"
fi

if [ -d "$REPO_ROOT/opencode/agent" ] && [ "$(ls -A "$REPO_ROOT/opencode/agent")" ]; then
    mkdir -p "$CONFIG_DIR/agent"
    cp -r "$REPO_ROOT/opencode/agent/"* "$CONFIG_DIR/agent/" 2>/dev/null || true
    ok "Installed agents to $CONFIG_DIR/agent/"
fi

if [ -d "$REPO_ROOT/opencode/skills" ] && [ "$(ls -A "$REPO_ROOT/opencode/skills")" ]; then
    mkdir -p "$CONFIG_DIR/skills"
    cp -r "$REPO_ROOT/opencode/skills/"* "$CONFIG_DIR/skills/" 2>/dev/null || true
    ok "Installed skills to $CONFIG_DIR/skills/"
fi

# ----- Optional: Tailscale -----
step "Tailscale (optional, for remote access)"
if command -v tailscale >/dev/null 2>&1 || [ -d "/Applications/Tailscale.app" ]; then
    ok "Tailscale already installed"
else
    read -rp "Install Tailscale for remote server access? (y/N) " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew install --cask tailscale
            ok "Tailscale installed. Launch from /Applications and sign in to the same account as the server."
        else
            warn "Install Homebrew first, or download Tailscale from https://tailscale.com/download"
        fi
    fi
fi

# ----- Validate connection -----
step "Validating connection to server"
SERVER_URL="http://$OLLAMA_HOST:$OLLAMA_PORT"

if curl -s --max-time 5 "$SERVER_URL/api/tags" > /tmp/ollama_tags.json 2>&1; then
    ok "Connected to $SERVER_URL"
    if command -v jq >/dev/null 2>&1; then
        echo "Available models on server:"
        jq -r '.models[].name' /tmp/ollama_tags.json | sed 's/^/  /'
    else
        echo "Models response:"
        cat /tmp/ollama_tags.json
    fi
    rm -f /tmp/ollama_tags.json
else
    warn "Could not reach server at $SERVER_URL"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Is the server running? Check on the server machine."
    echo "  2. Is the hostname correct? Try 'ping $OLLAMA_HOST'"
    echo "  3. If using Tailscale, run 'tailscale status' to verify both ends are signed in"
    echo "  4. Is the server firewall open on port $OLLAMA_PORT?"
fi

# ----- Done -----
echo ""
green "============================================"
green "  Client setup complete"
green "============================================"
echo ""
echo "Try it out:"
echo "  cd ~/some-code-project"
echo "  opencode"
echo ""
echo "Useful commands inside OpenCode:"
echo "  Tab          Toggle Plan/Build mode"
echo "  /init        Generate an AGENTS.md scaffold for the current project"
echo "  /compact     Condense conversation when context fills"
echo "  /help        Show all commands"
echo ""
echo "To set up project conventions, copy a template into your project:"
echo "  cp $REPO_ROOT/templates/AGENTS.generic.md ~/your-project/AGENTS.md"
echo "  cp $REPO_ROOT/templates/AGENTS.security-first.md ~/your-project/AGENTS.md  # security-sensitive projects"
echo "  cp $REPO_ROOT/templates/AGENTS.dotnet.md ~/your-project/AGENTS.md          # .NET projects"
echo ""
