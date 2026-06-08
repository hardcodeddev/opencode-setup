#!/usr/bin/env bash
#
# Sets up an OpenCode client on Linux.
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

# ----- Prompt for server hostname -----
echo ""
echo "Current server config: $OLLAMA_HOST:$OLLAMA_PORT (model: $OLLAMA_MODEL)"
read -rp "Press Enter to keep, or type a new hostname/IP: " new_host
if [ -n "$new_host" ]; then
    OLLAMA_HOST="$new_host"
    sed -i.bak "s|^OLLAMA_HOST=.*|OLLAMA_HOST=$new_host|" "$ENV_FILE"
    rm -f "${ENV_FILE}.bak"
fi

# ----- Install OpenCode -----
step "Checking for OpenCode"
if command -v opencode >/dev/null 2>&1; then
    ok "OpenCode already installed"
else
    echo "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
    ok "OpenCode installed (may need to open a new terminal)"
fi

# ----- Write OpenCode config -----
step "Writing OpenCode config"

CONFIG_DIR="$HOME/.config/opencode"
AUTH_DIR="$HOME/.local/share/opencode"
mkdir -p "$CONFIG_DIR" "$AUTH_DIR"

sed -e "s|{{OLLAMA_HOST}}|$OLLAMA_HOST|g" \
    -e "s|{{OLLAMA_PORT}}|$OLLAMA_PORT|g" \
    -e "s|{{OLLAMA_MODEL}}|$OLLAMA_MODEL|g" \
    -e "s|{{OLLAMA_MODEL_DISPLAY}}|$OLLAMA_MODEL|g" \
    "$REPO_ROOT/config/opencode.json.template" > "$CONFIG_DIR/opencode.json"
ok "Wrote $CONFIG_DIR/opencode.json"

cp "$REPO_ROOT/config/auth.json" "$AUTH_DIR/auth.json"
ok "Wrote $AUTH_DIR/auth.json"

# ----- Install commands and agents -----
step "Installing OpenCode commands and agents"
if [ -d "$REPO_ROOT/opencode/command" ] && [ "$(ls -A "$REPO_ROOT/opencode/command")" ]; then
    mkdir -p "$CONFIG_DIR/command"
    cp -r "$REPO_ROOT/opencode/command/"* "$CONFIG_DIR/command/" 2>/dev/null || true
    ok "Installed commands"
fi

if [ -d "$REPO_ROOT/opencode/agent" ] && [ "$(ls -A "$REPO_ROOT/opencode/agent")" ]; then
    mkdir -p "$CONFIG_DIR/agent"
    cp -r "$REPO_ROOT/opencode/agent/"* "$CONFIG_DIR/agent/" 2>/dev/null || true
    ok "Installed agents"
fi

if [ -d "$REPO_ROOT/opencode/skills" ] && [ "$(ls -A "$REPO_ROOT/opencode/skills")" ]; then
    mkdir -p "$CONFIG_DIR/skills"
    cp -r "$REPO_ROOT/opencode/skills/"* "$CONFIG_DIR/skills/" 2>/dev/null || true
    ok "Installed skills"
fi

# ----- Optional: Tailscale -----
step "Tailscale (optional)"
if command -v tailscale >/dev/null 2>&1; then
    ok "Tailscale already installed"
else
    read -rp "Install Tailscale for remote server access? (y/N) " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        curl -fsSL https://tailscale.com/install.sh | sh
        echo "Run 'sudo tailscale up' to sign in."
    fi
fi

# ----- Validate connection -----
step "Validating connection"
SERVER_URL="http://$OLLAMA_HOST:$OLLAMA_PORT"
if curl -s --max-time 5 "$SERVER_URL/api/tags" > /tmp/ollama_tags.json 2>&1; then
    ok "Connected to $SERVER_URL"
    if command -v jq >/dev/null 2>&1; then
        echo "Available models:"
        jq -r '.models[].name' /tmp/ollama_tags.json | sed 's/^/  /'
    fi
    rm -f /tmp/ollama_tags.json
else
    warn "Could not reach server at $SERVER_URL"
    echo "  Check that the server is running, the hostname is right, and the port is open."
fi

# ----- Done -----
echo ""
green "============================================"
green "  Client setup complete"
green "============================================"
echo ""
echo "Try it: cd ~/some-project && opencode"
echo ""
echo "Available commands inside OpenCode:"
echo "  /setup-project   Bootstrap any project — auto-detects stack, writes AGENTS.md"
echo "  /branch          Create a feature branch (never commits to main)"
echo "  /commit          Stage and commit with conventional message"
echo "  /pr              Create a PR for review (never auto-merges)"
echo "  /integrate-test  Generate hermetic integration tests"
echo "  /security        Run a security audit on code or diff"
echo "  /refactor        Safe refactor with test-first discipline"
echo "  /review          Code review with severity ratings"
echo "  /plan            Implementation planning (no code written)"
echo "  /test            Generate unit tests"
echo ""
echo "Subagents (invoke with @name or /agent name):"
echo "  @git-guardian       Enforces branch safety for all git ops"
echo "  @integration-tester Writes hermetic integration tests"
echo "  @security-auditor   Deep read-only security review"
echo "  @code-reviewer      Senior read-only code reviewer"
echo "  @debugger           Hypothesis-driven root cause analysis"
echo ""
echo "Project templates:"
echo "  cp $REPO_ROOT/templates/AGENTS.generic.md ~/your-project/AGENTS.md"
echo "  cp $REPO_ROOT/templates/AGENTS.security-first.md ~/your-project/AGENTS.md  # security-sensitive projects"
echo "  cp $REPO_ROOT/templates/AGENTS.dotnet.md ~/your-project/AGENTS.md          # .NET projects"
echo ""
