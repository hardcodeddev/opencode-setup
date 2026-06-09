<#
.SYNOPSIS
    Local dev setup — for machines that already have Ollama and Tailscale.
    Installs OpenCode and the skills/commands/agents. Points config to localhost.

.NOTES
    Run from the repo root:  .\setup\client\local-dev.ps1
    Does NOT require administrator privileges.
#>

$ErrorActionPreference = "Stop"

function Write-Step($msg)  { Write-Host ""; Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "  [!]  $msg" -ForegroundColor Yellow }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Resolve-Path (Join-Path $scriptDir "..\..")
$configDir = Join-Path $env:USERPROFILE ".config\opencode"
$authDir   = Join-Path $env:LOCALAPPDATA "opencode"

# ── 1. Verify Ollama is running ───────────────────────────────────────────────
Write-Step "Checking Ollama"
try {
    $tagsResponse = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" `
                        -TimeoutSec 3 -UseBasicParsing
} catch {
    Write-Warn "Ollama isn't responding on localhost:11434"
    Write-Host "  Start it: open Ollama from the system tray, or run 'ollama serve'"
    Write-Host "  Then re-run this script."
    exit 1
}
Write-Ok "Ollama is running"

# ── 2. Pick a model ───────────────────────────────────────────────────────────
Write-Step "Available models"
$models = ($tagsResponse.Content | ConvertFrom-Json).models | ForEach-Object { $_.name }

if (-not $models) {
    Write-Warn "No models found. Pull one first:  ollama pull qwen3-coder:30b"
    exit 1
}

$i = 1
foreach ($m in $models) { Write-Host "  $i) $m"; $i++ }
Write-Host ""
$modelNum = Read-Host "  Choose model number [1]"
if (-not $modelNum) { $modelNum = 1 }
$chosenModel = @($models)[[int]$modelNum - 1]

if (-not $chosenModel) { Write-Warn "Invalid selection"; exit 1 }
Write-Ok "Using model: $chosenModel"

# ── 3. Install OpenCode ───────────────────────────────────────────────────────
Write-Step "Checking OpenCode"
$hasOpencode = [bool](Get-Command opencode -ErrorAction SilentlyContinue)
if ($hasOpencode) {
    Write-Ok "OpenCode already installed ($((Get-Command opencode).Source))"
} else {
    $hasScoop = [bool](Get-Command scoop -ErrorAction SilentlyContinue)
    if (-not $hasScoop) {
        Write-Host "  Installing Scoop..."
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression
    }
    try {
        scoop bucket add extras 2>$null
        scoop install extras/opencode
        Write-Ok "OpenCode installed via Scoop"
    } catch {
        Write-Host "  Scoop failed, trying npm..."
        npm install -g opencode-ai
        Write-Ok "OpenCode installed via npm"
    }
}

# ── 4. Write config ───────────────────────────────────────────────────────────
Write-Step "Writing OpenCode config"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null
New-Item -ItemType Directory -Force -Path $authDir   | Out-Null

$configPath = Join-Path $configDir "opencode.json"
if (Test-Path $configPath) {
    Copy-Item $configPath "$configPath.bak" -Force
    Write-Warn "Existing opencode.json backed up to opencode.json.bak"
}

$json = @"
{
  "`$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "$chosenModel": {
          "name": "$chosenModel",
          "tools": true
        }
      }
    }
  },
  "model": "ollama/$chosenModel"
}
"@

Set-Content -Path $configPath -Value $json -NoNewline
Write-Ok "Wrote $configPath  (model: $chosenModel, host: localhost)"

Copy-Item (Join-Path $repoRoot "config\auth.json") (Join-Path $authDir "auth.json") -Force

# ── 5. Install commands / agents / skills ─────────────────────────────────────
Write-Step "Installing commands, agents, and skills"

$dirs = @("command","agent","skills")
foreach ($d in $dirs) {
    $src  = Join-Path $repoRoot "opencode\$d"
    $dest = Join-Path $configDir $d
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item -Path "$src\*" -Destination $dest -Recurse -Force
    Write-Ok "$d -> $dest"
}

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════" -ForegroundColor Green
Write-Host "  Done" -ForegroundColor Green
Write-Host "════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  Model:  $chosenModel  (localhost)"
Write-Host ""
Write-Host "  Start coding (use Windows Terminal):"
Write-Host "    cd C:\your-project"
Write-Host "    opencode"
Write-Host ""
Write-Host "  First time in a project:"
Write-Host "    /setup-project"
Write-Host ""
Write-Host "  Onboard all existing repos:"
Write-Host "    /init-all-repos"
Write-Host ""
