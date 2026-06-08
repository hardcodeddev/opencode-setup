#!/usr/bin/env bash
#
# Sets up an Ollama server on macOS for use with the OpenCode workflow.
#
# This script will:
#   - Install Ollama (if not already present) via Homebrew or installer
#   - Configure Ollama environment via launchd
#   - Pull the configured model
#   - Build a context-tuned variant
#   - Optionally install Tailscale
#   - Print verification steps
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
    echo "Created config/env from template. Edit it now if you want to customize defaults."
    echo "Press Enter to continue with defaults, or Ctrl+C to edit and re-run."
    read -r
fi

# Source the env file (it's KEY=VALUE format, safe to source)
# shellcheck disable=SC1090
source "$ENV_FILE"

echo ""
echo "Configuration:"
echo "  Model:           $OLLAMA_MODEL"
echo "  Port:            $OLLAMA_PORT"
echo "  Context length:  $OLLAMA_CONTEXT_LENGTH"
echo "  Keep alive:      $OLLAMA_KEEP_ALIVE"

# ----- Install Ollama -----
step "Checking for Ollama"
if command -v ollama >/dev/null 2>&1; then
    ok "Ollama already installed: $(command -v ollama)"
else
    if command -v brew >/dev/null 2>&1; then
        echo "Installing Ollama via Homebrew..."
        brew install --cask ollama
    else
        echo "Homebrew not found. Installing Ollama directly..."
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    ok "Ollama installed"
fi

# ----- Configure environment via launchctl -----
# On macOS, environment vars for GUI-launched apps (like Ollama.app) need to be
# set via launchctl setenv, not just in shell rc files.
step "Configuring Ollama environment"

set_launchctl_env() {
    local key="$1"
    local value="$2"
    launchctl setenv "$key" "$value"
    echo "  $key = $value"
}

set_launchctl_env "OLLAMA_HOST" "0.0.0.0:$OLLAMA_PORT"
set_launchctl_env "OLLAMA_ORIGINS" "$OLLAMA_ORIGINS"
set_launchctl_env "OLLAMA_KEEP_ALIVE" "$OLLAMA_KEEP_ALIVE"
set_launchctl_env "OLLAMA_CONTEXT_LENGTH" "$OLLAMA_CONTEXT_LENGTH"
set_launchctl_env "OLLAMA_FLASH_ATTENTION" "1"
set_launchctl_env "OLLAMA_KV_CACHE_TYPE" "q8_0"
set_launchctl_env "OLLAMA_NUM_PARALLEL" "1"
set_launchctl_env "OLLAMA_MAX_LOADED_MODELS" "1"

ok "Environment variables set via launchctl"
warn "These persist until reboot. To make them permanent across reboots:"
echo "  Add the launchctl setenv commands to a LaunchAgent or ~/.zprofile and use the GUI Ollama app."

# ----- Restart Ollama -----
step "Restarting Ollama"
if pgrep -x "Ollama" > /dev/null || pgrep -x "ollama" > /dev/null; then
    osascript -e 'quit app "Ollama"' 2>/dev/null || true
    pkill -x ollama 2>/dev/null || true
    sleep 2
fi

# Try to launch the GUI app first; fall back to ollama serve
if [ -d "/Applications/Ollama.app" ]; then
    open -a Ollama
    ok "Launched Ollama.app"
else
    nohup ollama serve > /tmp/ollama.log 2>&1 &
    ok "Launched ollama serve in background (log: /tmp/ollama.log)"
fi
sleep 3

# ----- Pull model -----
step "Pulling model: $OLLAMA_MODEL"
echo "(This can take a while for large models...)"
ollama pull "$OLLAMA_MODEL"
ok "Model pulled"

# ----- Build context-tuned variant -----
step "Building context-tuned variant: ${OLLAMA_MODEL}-tuned"
TEMP_MODELFILE="$(mktemp)"
sed -e "s|{{OLLAMA_MODEL}}|$OLLAMA_MODEL|g" \
    -e "s|{{OLLAMA_CONTEXT_LENGTH}}|$OLLAMA_CONTEXT_LENGTH|g" \
    "$REPO_ROOT/config/Modelfile" > "$TEMP_MODELFILE"

if ollama create "${OLLAMA_MODEL}-tuned" -f "$TEMP_MODELFILE"; then
    ok "Built ${OLLAMA_MODEL}-tuned"
else
    warn "Failed to build tuned variant. The launchctl env var will still apply."
fi
rm -f "$TEMP_MODELFILE"

# ----- Optional: Tailscale -----
step "Tailscale (optional, for remote access)"
if command -v tailscale >/dev/null 2>&1; then
    ok "Tailscale already installed"
else
    read -rp "Install Tailscale for remote access? (y/N) " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew install --cask tailscale
            ok "Tailscale installed. Launch it from /Applications and sign in."
        else
            warn "Homebrew not available. Install Tailscale manually from https://tailscale.com/download"
        fi
    fi
fi

# ----- Verification -----
step "Verifying setup"
echo "Checking Ollama is listening..."
if curl -s --max-time 5 "http://localhost:$OLLAMA_PORT/api/tags" > /dev/null; then
    ok "Ollama responding on localhost:$OLLAMA_PORT"
else
    warn "Ollama not yet responding. May still be starting up."
fi

echo ""
echo "Installed models:"
ollama list

# ----- Done -----
echo ""
green "============================================"
green "  Server setup complete"
green "============================================"
echo ""
echo "Next steps:"
echo "  1. From a client machine, install Tailscale and sign in to the same account."
echo "  2. Find this machine's Tailscale name in the admin console."
echo "  3. Test connection from the client:"
echo "       curl http://<this-machine-name>:$OLLAMA_PORT/v1/models"
echo "  4. On the client, run setup/client/<os>.sh in this repo."
echo ""
