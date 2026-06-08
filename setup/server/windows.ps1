<#
.SYNOPSIS
    Sets up an Ollama server on Windows for use with the OpenCode workflow.

.DESCRIPTION
    This script will:
    - Install Ollama (if not already present) via winget
    - Configure Ollama to accept network connections (OLLAMA_HOST=0.0.0.0)
    - Set Ollama environment variables for context, flash attention, KV cache
    - Open Windows Firewall on port 11434
    - Pull the configured model
    - Optionally install Tailscale for remote access
    - Optionally disable sleep on AC power
    - Print verification steps

.NOTES
    Run from PowerShell with administrator privileges.
    Reads configuration from config/env (copy from config/env.example).
#>

$ErrorActionPreference = "Stop"

# ----- Color output helpers -----
function Write-Step($msg) { Write-Host ""; Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# ----- Admin check -----
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Err "This script must be run as Administrator."
    Write-Host "Right-click PowerShell and 'Run as Administrator', then re-run."
    exit 1
}

# ----- Load configuration -----
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..\..")
$envFile = Join-Path $repoRoot "config\env"

if (-not (Test-Path $envFile)) {
    Write-Step "Initializing configuration"
    $exampleFile = Join-Path $repoRoot "config\env.example"
    Copy-Item $exampleFile $envFile
    Write-Host "Created config/env from template. Edit it now if you want to customize defaults."
    Write-Host "Press Enter to continue with defaults, or Ctrl+C to edit and re-run."
    Read-Host
}

# Parse the env file (simple KEY=VALUE format)
$config = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([A-Z_]+)\s*=\s*(.+?)\s*$') {
        $config[$matches[1]] = $matches[2]
    }
}

$model = $config['OLLAMA_MODEL']
$port = $config['OLLAMA_PORT']
$contextLength = $config['OLLAMA_CONTEXT_LENGTH']
$keepAlive = $config['OLLAMA_KEEP_ALIVE']
$origins = $config['OLLAMA_ORIGINS']

Write-Host ""
Write-Host "Configuration:" -ForegroundColor White
Write-Host "  Model:           $model"
Write-Host "  Port:            $port"
Write-Host "  Context length:  $contextLength"
Write-Host "  Keep alive:      $keepAlive"

# ----- Install Ollama -----
Write-Step "Checking for Ollama"
$ollamaInstalled = Get-Command ollama -ErrorAction SilentlyContinue
if ($ollamaInstalled) {
    Write-Success "Ollama already installed: $($ollamaInstalled.Source)"
} else {
    Write-Host "Installing Ollama via winget..."
    winget install --id Ollama.Ollama --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Err "winget install failed. Install manually from https://ollama.com/download and re-run."
        exit 1
    }
    Write-Success "Ollama installed"
    Write-Warn "You may need to close and reopen PowerShell for the 'ollama' command to be available."
    Write-Host "After that, re-run this script."
    exit 0
}

# ----- Set Ollama environment variables system-wide -----
Write-Step "Configuring Ollama environment variables"

$envVars = @{
    "OLLAMA_HOST"             = "0.0.0.0:$port"
    "OLLAMA_ORIGINS"          = $origins
    "OLLAMA_KEEP_ALIVE"       = $keepAlive
    "OLLAMA_CONTEXT_LENGTH"   = $contextLength
    "OLLAMA_FLASH_ATTENTION"  = "1"
    "OLLAMA_KV_CACHE_TYPE"    = "q8_0"
    "OLLAMA_NUM_PARALLEL"     = "1"
    "OLLAMA_MAX_LOADED_MODELS" = "1"
}

foreach ($key in $envVars.Keys) {
    [Environment]::SetEnvironmentVariable($key, $envVars[$key], [EnvironmentVariableTarget]::Machine)
    Write-Host "  $key = $($envVars[$key])"
}
Write-Success "Environment variables set system-wide"

# ----- Open firewall -----
Write-Step "Configuring Windows Firewall"
$ruleName = "Ollama (OpenCode Workflow)"
$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Success "Firewall rule already exists"
} else {
    New-NetFirewallRule -DisplayName $ruleName `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $port `
        -Action Allow `
        -Profile Private,Domain | Out-Null
    Write-Success "Firewall opened on TCP $port (Private and Domain profiles only)"
    Write-Warn "Note: rule does NOT apply to Public networks. If on a 'Public' network at home, change your network profile to 'Private' in Settings > Network."
}

# ----- Restart Ollama service to pick up new env vars -----
Write-Step "Restarting Ollama"
$ollamaProcess = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if ($ollamaProcess) {
    Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}
Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
Start-Sleep -Seconds 3
Write-Success "Ollama restarted with new configuration"

# ----- Pull model -----
Write-Step "Pulling model: $model"
Write-Host "(This can take a while for large models...)"
ollama pull $model
if ($LASTEXITCODE -ne 0) {
    Write-Err "Failed to pull model $model"
    Write-Host "Check the model name in config/env. Run 'ollama list' to see installed models."
    exit 1
}
Write-Success "Model pulled"

# ----- Build context-tuned variant (optional but recommended) -----
Write-Step "Building context-tuned variant: ${model}-tuned"
$modelfileTemplate = Get-Content (Join-Path $repoRoot "config\Modelfile") -Raw
$modelfileContent = $modelfileTemplate -replace '{{OLLAMA_MODEL}}', $model -replace '{{OLLAMA_CONTEXT_LENGTH}}', $contextLength
$tempModelfile = Join-Path $env:TEMP "opencode-modelfile"
Set-Content -Path $tempModelfile -Value $modelfileContent -NoNewline

$tunedName = "$model-tuned"
ollama create $tunedName -f $tempModelfile
Remove-Item $tempModelfile

if ($LASTEXITCODE -eq 0) {
    Write-Success "Built $tunedName"
    Write-Host "  Use this name in clients to get the bigger context without relying on env vars."
} else {
    Write-Warn "Failed to build tuned variant. The env var OLLAMA_CONTEXT_LENGTH will still apply."
}

# ----- Optional: Tailscale -----
Write-Step "Tailscale (optional, for remote access)"
$tailscaleInstalled = Get-Command tailscale -ErrorAction SilentlyContinue
if ($tailscaleInstalled) {
    Write-Success "Tailscale already installed"
} else {
    $installTailscale = Read-Host "Install Tailscale for remote access? (y/N)"
    if ($installTailscale -eq "y" -or $installTailscale -eq "Y") {
        winget install --id tailscale.tailscale --silent --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Tailscale installed"
            Write-Host "  Launch Tailscale from the Start Menu and sign in."
            Write-Host "  Then in the Tailscale admin console, rename this machine to a friendly hostname."
        } else {
            Write-Warn "Tailscale install failed. Install manually from https://tailscale.com/download"
        }
    }
}

# ----- Optional: Disable sleep on AC -----
Write-Step "Power settings (optional)"
$disableSleep = Read-Host "Prevent sleep when plugged in? Recommended for always-on server. (y/N)"
if ($disableSleep -eq "y" -or $disableSleep -eq "Y") {
    powercfg /change standby-timeout-ac 0
    Write-Success "Sleep disabled on AC power"
}

# ----- Verification -----
Write-Step "Verifying setup"

Write-Host "Checking Ollama is listening on 0.0.0.0:$port..."
$listening = netstat -an | Select-String "0\.0\.0\.0:$port"
if ($listening) {
    Write-Success "Ollama is listening on all interfaces"
} else {
    Write-Warn "Ollama may still be binding to localhost only. Try:"
    Write-Host "  1. Sign out and back in, or reboot (env vars need a fresh session)"
    Write-Host "  2. Right-click Ollama in system tray, Quit, then relaunch from Start Menu"
}

Write-Host "Checking model list..."
$models = ollama list 2>&1
Write-Host $models

# ----- Done -----
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Server setup complete" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. From a client machine, install Tailscale and sign in to the same account."
Write-Host "  2. Find this machine's Tailscale name in the admin console."
Write-Host "  3. Test connection from the client:"
Write-Host "       curl http://<this-machine-name>:$port/v1/models"
Write-Host "  4. On the client, run the client setup script in this repo."
Write-Host ""
Write-Host "Useful local commands:"
Write-Host "  ollama list        # Show installed models"
Write-Host "  ollama ps          # Show running models with actual context size"
Write-Host "  ollama run $model  # Interactive test"
Write-Host ""
