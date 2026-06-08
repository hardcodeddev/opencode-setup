#!/usr/bin/env bash
#
# Sets up an Ollama server on Linux for use with the OpenCode workflow.
#
# Supports systemd-based distros (Ubuntu, Debian, Fedora, Arch, etc.)
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

# ----- Sudo check -----
if [ "$EUID" -eq 0 ]; then
    warn "Running as root. The script will still work but ollama models will be owned by root."
fi

# ----- Locate repo root -----
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
ENV_FILE="$REPO_ROOT/config/env"
EXAMPLE_FILE="$REPO_ROOT/config/env.example"

# ----- Initialize config -----
if [ ! -f "$ENV_FILE" ]; then
    step "Initializing configuration"
    cp "$EXAMPLE_FILE" "$ENV_FILE"
    echo "Created config/env from template. Edit it now to customize, or press Enter for defaults."
    read -r
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

echo ""
echo "Configuration:"
echo "  Model:           $OLLAMA_MODEL"
echo "  Port:            $OLLAMA_PORT"
echo "  Context length:  $OLLAMA_CONTEXT_LENGTH"

# ----- Install Ollama -----
step "Checking for Ollama"
if command -v ollama >/dev/null 2>&1; then
    ok "Ollama already installed: $(command -v ollama)"
else
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    ok "Ollama installed"
fi

# ----- Configure systemd service environment -----
step "Configuring Ollama systemd service"

# Create a systemd override so the env vars stick across restarts
SYSTEMD_OVERRIDE_DIR="/etc/systemd/system/ollama.service.d"
SYSTEMD_OVERRIDE_FILE="$SYSTEMD_OVERRIDE_DIR/override.conf"

sudo mkdir -p "$SYSTEMD_OVERRIDE_DIR"
sudo tee "$SYSTEMD_OVERRIDE_FILE" > /dev/null <<EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:$OLLAMA_PORT"
Environment="OLLAMA_ORIGINS=$OLLAMA_ORIGINS"
Environment="OLLAMA_KEEP_ALIVE=$OLLAMA_KEEP_ALIVE"
Environment="OLLAMA_CONTEXT_LENGTH=$OLLAMA_CONTEXT_LENGTH"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KV_CACHE_TYPE=q8_0"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
EOF

ok "Wrote systemd override: $SYSTEMD_OVERRIDE_FILE"

sudo systemctl daemon-reload
sudo systemctl restart ollama
sleep 3
ok "Ollama service restarted with new configuration"

# ----- Firewall (best effort) -----
step "Configuring firewall (best effort)"
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow "$OLLAMA_PORT/tcp" comment "Ollama (OpenCode Workflow)" || warn "ufw not active"
    ok "ufw rule added"
elif command -v firewall-cmd >/dev/null 2>&1; then
    sudo firewall-cmd --permanent --add-port="${OLLAMA_PORT}/tcp"
    sudo firewall-cmd --reload
    ok "firewalld rule added"
else
    warn "No supported firewall detected (ufw, firewalld). If your distro uses iptables/nftables, open TCP $OLLAMA_PORT manually."
fi

# ----- Pull model -----
step "Pulling model: $OLLAMA_MODEL"
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
fi
rm -f "$TEMP_MODELFILE"

# ----- Optional: Tailscale -----
step "Tailscale (optional, for remote access)"
if command -v tailscale >/dev/null 2>&1; then
    ok "Tailscale already installed"
else
    read -rp "Install Tailscale for remote access? (y/N) " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        curl -fsSL https://tailscale.com/install.sh | sh
        echo "Run 'sudo tailscale up' to sign in."
    fi
fi

# ----- Verification -----
step "Verifying setup"
if curl -s --max-time 5 "http://localhost:$OLLAMA_PORT/api/tags" > /dev/null; then
    ok "Ollama responding"
else
    warn "Ollama not responding yet. Check 'systemctl status ollama' and 'journalctl -u ollama -f'."
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
echo "  1. Note this machine's IP (or Tailscale name if installed)"
echo "  2. On the client, test: curl http://<this-host>:$OLLAMA_PORT/v1/models"
echo "  3. Run setup/client/<os>.sh on the client machine"
echo ""
