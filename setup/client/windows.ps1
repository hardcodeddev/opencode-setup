<#
.SYNOPSIS
    Sets up an OpenCode client on Windows.

.DESCRIPTION
    This script will:
    - Install OpenCode via Scoop (clean Windows install path)
    - Prompt for the Ollama server hostname
    - Write OpenCode config files to the correct Windows paths
    - Install commands and agents from this repo
    - Validate the connection to the server

.NOTES
    Does NOT require administrator privileges (uses Scoop).
#>

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host ""; Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# ----- Locate repo root -----
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..\..")
$envFile = Join-Path $repoRoot "config\env"

# ----- Initialize config -----
if (-not (Test-Path $envFile)) {
    Write-Step "Initializing configuration"
    Copy-Item (Join-Path $repoRoot "config\env.example") $envFile
}

# Parse env file
$config = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([A-Z_]+)\s*=\s*(.+?)\s*$') {
        $config[$matches[1]] = $matches[2]
    }
}

# ----- Prompt for server hostname -----
$ollamaHost = $config['OLLAMA_HOST']
$ollamaPort = $config['OLLAMA_PORT']
$ollamaModel = $config['OLLAMA_MODEL']

Write-Host ""
Write-Host "Current server config: ${ollamaHost}:${ollamaPort} (model: $ollamaModel)"
$newHost = Read-Host "Press Enter to keep, or type a new hostname/IP (e.g., gpu-rig, 192.168.1.50, localhost)"
if ($newHost) {
    $ollamaHost = $newHost
    # Update env file
    (Get-Content $envFile) -replace '^OLLAMA_HOST=.*', "OLLAMA_HOST=$newHost" | Set-Content $envFile
    Write-Success "Updated config/env"
}

# ----- Install OpenCode via Scoop -----
Write-Step "Checking for OpenCode"
$opencodeInstalled = Get-Command opencode -ErrorAction SilentlyContinue
if ($opencodeInstalled) {
    Write-Success "OpenCode already installed: $($opencodeInstalled.Source)"
} else {
    # Check for Scoop
    $scoopInstalled = Get-Command scoop -ErrorAction SilentlyContinue
    if (-not $scoopInstalled) {
        Write-Host "Installing Scoop (no admin needed)..."
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression
        Write-Success "Scoop installed"
    }

    Write-Host "Installing OpenCode via Scoop..."
    scoop bucket add extras 2>$null
    scoop install extras/opencode
    Write-Success "OpenCode installed"
}

# ----- Write OpenCode config -----
Write-Step "Writing OpenCode config"

$configDir = Join-Path $env:USERPROFILE ".config\opencode"
$authDir = Join-Path $env:LOCALAPPDATA "opencode"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null
New-Item -ItemType Directory -Force -Path $authDir | Out-Null

# Generate opencode.json from template
$template = Get-Content (Join-Path $repoRoot "config\opencode.json.template") -Raw
$opencodeJson = $template `
    -replace '{{OLLAMA_HOST}}', $ollamaHost `
    -replace '{{OLLAMA_PORT}}', $ollamaPort `
    -replace '{{OLLAMA_MODEL}}', $ollamaModel `
    -replace '{{OLLAMA_MODEL_DISPLAY}}', $ollamaModel

Set-Content -Path (Join-Path $configDir "opencode.json") -Value $opencodeJson -NoNewline
Write-Success "Wrote $configDir\opencode.json"

# Copy auth.json placeholder
Copy-Item (Join-Path $repoRoot "config\auth.json") (Join-Path $authDir "auth.json") -Force
Write-Success "Wrote $authDir\auth.json"

# ----- Install commands and agents -----
Write-Step "Installing OpenCode commands and agents"

$commandSrc = Join-Path $repoRoot "opencode\command"
$agentSrc = Join-Path $repoRoot "opencode\agent"

if ((Test-Path $commandSrc) -and (Get-ChildItem $commandSrc -Force | Measure-Object).Count -gt 0) {
    $commandDest = Join-Path $configDir "command"
    New-Item -ItemType Directory -Force -Path $commandDest | Out-Null
    Copy-Item -Path "$commandSrc\*" -Destination $commandDest -Recurse -Force
    Write-Success "Installed commands"
}

if ((Test-Path $agentSrc) -and (Get-ChildItem $agentSrc -Force | Measure-Object).Count -gt 0) {
    $agentDest = Join-Path $configDir "agent"
    New-Item -ItemType Directory -Force -Path $agentDest | Out-Null
    Copy-Item -Path "$agentSrc\*" -Destination $agentDest -Recurse -Force
    Write-Success "Installed agents"
}

# ----- Optional: Tailscale -----
Write-Step "Tailscale (optional)"
$tailscaleInstalled = Get-Command tailscale -ErrorAction SilentlyContinue
if ($tailscaleInstalled) {
    Write-Success "Tailscale already installed"
} else {
    $installTailscale = Read-Host "Install Tailscale for remote server access? (y/N)"
    if ($installTailscale -eq "y" -or $installTailscale -eq "Y") {
        try {
            winget install --id tailscale.tailscale --silent --accept-source-agreements --accept-package-agreements
            Write-Success "Tailscale installed. Launch from Start Menu and sign in."
        } catch {
            Write-Warn "winget failed. Install manually from https://tailscale.com/download"
        }
    }
}

# ----- Validate connection -----
Write-Step "Validating connection to server"
$serverUrl = "http://${ollamaHost}:${ollamaPort}"
try {
    $response = Invoke-WebRequest -Uri "$serverUrl/api/tags" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Success "Connected to $serverUrl"
        $models = ($response.Content | ConvertFrom-Json).models
        Write-Host "Available models on server:"
        foreach ($m in $models) { Write-Host "  $($m.name)" }
    }
} catch {
    Write-Warn "Could not reach server at $serverUrl"
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "  1. Is the server running?"
    Write-Host "  2. Is the hostname correct? Try 'Test-NetConnection $ollamaHost -Port $ollamaPort'"
    Write-Host "  3. If using Tailscale, run 'tailscale status' to verify both ends are signed in"
}

# ----- Done -----
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Client setup complete" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Use Windows Terminal (not cmd or PowerShell ISE) to run OpenCode."
Write-Host "  Install from the Microsoft Store if you don't have it."
Write-Host ""
Write-Host "Try it out:"
Write-Host "  cd C:\path\to\code\project"
Write-Host "  opencode"
Write-Host ""
Write-Host "Useful commands inside OpenCode:"
Write-Host "  Tab          Toggle Plan/Build mode"
Write-Host "  /init        Generate AGENTS.md scaffold for the project"
Write-Host "  /compact     Condense conversation"
Write-Host "  /help        Show all commands"
Write-Host ""
Write-Host "To bootstrap project conventions:"
Write-Host "  Copy-Item $repoRoot\templates\AGENTS.dotnet.md C:\your-project\AGENTS.md"
Write-Host ""
