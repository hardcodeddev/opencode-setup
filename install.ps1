<#
.SYNOPSIS
    OpenCode Setup — smart incremental installer for Windows

.DESCRIPTION
    Detects what you already have installed and offers the right options.
    Safe to run multiple times — never overwrites your existing opencode.json.

.PARAMETER Skills
    Non-interactive: install commands/agents/skills only

.PARAMETER Update
    Non-interactive: update existing commands/agents/skills to latest

.PARAMETER Full
    Non-interactive: full setup including OpenCode + Ollama config

.EXAMPLE
    .\install.ps1             # interactive menu
    .\install.ps1 -Skills    # just install skills
    .\install.ps1 -Update    # update existing skills
    .\install.ps1 -Full      # full setup
#>

param(
    [switch]$Skills,
    [switch]$Update,
    [switch]$Full
)

$ErrorActionPreference = "Stop"

# ─── Colour helpers ───────────────────────────────────────────────────────────
function Write-Step($msg)    { Write-Host ""; Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)      { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function Write-Skip($msg)    { Write-Host "  [-]  $msg" -ForegroundColor DarkGray }
function Write-Bold($msg)    { Write-Host $msg -ForegroundColor White }
function Write-Divider()     { Write-Host "─────────────────────────────────────────────────────" }

# ─── Locate repo root ─────────────────────────────────────────────────────────
$repoRoot = $PSScriptRoot

# ─── OpenCode config paths on Windows ────────────────────────────────────────
$configDir = Join-Path $env:USERPROFILE ".config\opencode"
$authDir   = Join-Path $env:LOCALAPPDATA "opencode"

# ─── Detect current state ─────────────────────────────────────────────────────
$hasOpencode  = [bool](Get-Command opencode -ErrorAction SilentlyContinue)
$hasConfig    = Test-Path (Join-Path $configDir "opencode.json")
$hasCommands  = (Test-Path (Join-Path $configDir "command")) -and
                ((Get-ChildItem (Join-Path $configDir "command") -Filter "*.md" -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)
$hasAgents    = (Test-Path (Join-Path $configDir "agent")) -and
                ((Get-ChildItem (Join-Path $configDir "agent")   -Filter "*.md" -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)
$hasSkills    = (Test-Path (Join-Path $configDir "skills")) -and
                ((Get-ChildItem (Join-Path $configDir "skills")  -Filter "*.md" -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)

# ─── Functions ────────────────────────────────────────────────────────────────

function Print-Status {
    Write-Host ""
    Write-Bold "Current state"
    Write-Divider

    if ($hasOpencode) {
        Write-Ok  "OpenCode installed  ($((Get-Command opencode).Source))"
    } else {
        Write-Warn "OpenCode not found on PATH"
    }

    if ($hasConfig) {
        Write-Ok  "opencode.json found — will not touch it"
    } else {
        Write-Warn "No opencode.json — provider not configured yet"
    }

    Write-Host ""

    if ($hasCommands) { Write-Ok  "Commands installed  ($configDir\command\)" }
    else              { Write-Warn "Commands not installed" }

    if ($hasAgents)   { Write-Ok  "Agents installed    ($configDir\agent\)" }
    else              { Write-Warn "Agents not installed" }

    if ($hasSkills)   { Write-Ok  "Skills installed    ($configDir\skills\)" }
    else              { Write-Warn "Skills not installed" }

    Write-Divider
}

function Install-Skills {
    Write-Step "Installing commands, agents, and skills"

    $commandSrc = Join-Path $repoRoot "opencode\command"
    $agentSrc   = Join-Path $repoRoot "opencode\agent"
    $skillsSrc  = Join-Path $repoRoot "opencode\skills"

    $commandDest = Join-Path $configDir "command"
    $agentDest   = Join-Path $configDir "agent"
    $skillsDest  = Join-Path $configDir "skills"

    New-Item -ItemType Directory -Force -Path $commandDest | Out-Null
    Copy-Item -Path "$commandSrc\*" -Destination $commandDest -Recurse -Force
    Write-Ok "Commands  → $commandDest"

    New-Item -ItemType Directory -Force -Path $agentDest | Out-Null
    Copy-Item -Path "$agentSrc\*" -Destination $agentDest -Recurse -Force
    Write-Ok "Agents    → $agentDest"

    New-Item -ItemType Directory -Force -Path $skillsDest | Out-Null
    Copy-Item -Path "$skillsSrc\*" -Destination $skillsDest -Recurse -Force
    Write-Ok "Skills    → $skillsDest"
}

function Install-OpenCode {
    Write-Step "Installing OpenCode"
    if ($hasOpencode) {
        Write-Skip "OpenCode already installed — skipping"
        return
    }

    # Try Scoop first (cleanest Windows path), fall back to npm
    $hasScoop = [bool](Get-Command scoop -ErrorAction SilentlyContinue)
    if (-not $hasScoop) {
        Write-Host "  Installing Scoop (no admin required)..."
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression
    }

    try {
        scoop bucket add extras 2>$null
        scoop install extras/opencode
        Write-Ok "OpenCode installed via Scoop"
    } catch {
        Write-Warn "Scoop install failed, trying npm..."
        npm install -g opencode-ai
        Write-Ok "OpenCode installed via npm"
    }
}

function Configure-Ollama {
    Write-Step "Configuring Ollama provider"

    if ($hasConfig) {
        Write-Skip "opencode.json already exists — skipping Ollama config"
        Write-Host "      To reconfigure, edit $configDir\opencode.json manually."
        return
    }

    $envFile     = Join-Path $repoRoot "config\env"
    $exampleFile = Join-Path $repoRoot "config\env.example"

    if (-not (Test-Path $envFile)) {
        Copy-Item $exampleFile $envFile
    }

    # Parse env file into a hashtable
    $envVars = @{}
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([A-Z_]+)\s*=\s*(.+?)\s*$') {
            $envVars[$matches[1]] = $matches[2]
        }
    }

    $ollamaHost  = $envVars['OLLAMA_HOST']
    $ollamaPort  = $envVars['OLLAMA_PORT']
    $ollamaModel = $envVars['OLLAMA_MODEL']

    Write-Host ""
    Write-Host "  Current config: ${ollamaHost}:${ollamaPort}  (model: $ollamaModel)"
    $newHost = Read-Host "  Ollama server hostname or IP [$ollamaHost]"
    if ($newHost) {
        $ollamaHost = $newHost
        (Get-Content $envFile) -replace '^OLLAMA_HOST=.*', "OLLAMA_HOST=$newHost" |
            Set-Content $envFile
    }

    New-Item -ItemType Directory -Force -Path $configDir | Out-Null
    New-Item -ItemType Directory -Force -Path $authDir   | Out-Null

    $template = Get-Content (Join-Path $repoRoot "config\opencode.json.template") -Raw
    $json = $template `
        -replace '{{OLLAMA_HOST}}',          $ollamaHost  `
        -replace '{{OLLAMA_PORT}}',          $ollamaPort  `
        -replace '{{OLLAMA_MODEL}}',         $ollamaModel `
        -replace '{{OLLAMA_MODEL_DISPLAY}}', $ollamaModel

    Set-Content -Path (Join-Path $configDir "opencode.json") -Value $json -NoNewline
    Write-Ok "Wrote $configDir\opencode.json"

    Copy-Item (Join-Path $repoRoot "config\auth.json") (Join-Path $authDir "auth.json") -Force
    Write-Ok "Wrote $authDir\auth.json"

    # Quick connection check
    $serverUrl = "http://${ollamaHost}:${ollamaPort}"
    try {
        $r = Invoke-WebRequest -Uri "$serverUrl/api/tags" -TimeoutSec 5 -UseBasicParsing
        if ($r.StatusCode -eq 200) { Write-Ok "Reachable: $serverUrl" }
    } catch {
        Write-Warn "Could not reach $serverUrl — check server is running and hostname is correct"
    }
}

function Print-NextSteps {
    Write-Host ""
    Write-Bold "All done. What to do next:"
    Write-Host ""
    Write-Host "  1. Open any project in OpenCode (use Windows Terminal):"
    Write-Host "       cd C:\your-project"
    Write-Host "       opencode"
    Write-Host ""
    Write-Host "  2. Onboard all your existing repos at once:"
    Write-Host "       /init-all-repos"
    Write-Host "     (dry-run by default — add --write to apply)"
    Write-Host ""
    Write-Host "  3. Fully configure a specific project:"
    Write-Host "       /setup-project"
    Write-Host ""
    Write-Host "  4. Before every code change:"
    Write-Host "       /branch feat/my-feature   <- creates branch, never touches main"
    Write-Host "       /commit                   <- scans for secrets, commits, pushes"
    Write-Host "       /pr                       <- creates PR for your review, never merges"
    Write-Host ""
}

# ─── Non-interactive flags ────────────────────────────────────────────────────
if ($Skills) {
    Print-Status
    Install-Skills
    Print-NextSteps
    exit 0
}

if ($Update) {
    Print-Status
    Install-Skills
    Write-Ok "Commands, agents, and skills updated to latest version"
    Print-NextSteps
    exit 0
}

if ($Full) {
    Print-Status
    Install-OpenCode
    Configure-Ollama
    Install-Skills
    Print-NextSteps
    exit 0
}

# ─── Interactive menu ─────────────────────────────────────────────────────────
Write-Host ""
Write-Bold "OpenCode Setup"
Write-Host "════════════════════════════════════════════════════════"

Print-Status

Write-Host ""

if ($hasOpencode -and $hasConfig -and $hasCommands -and $hasAgents -and $hasSkills) {
    # Everything installed
    Write-Bold "Everything looks installed."
    Write-Host ""
    Write-Host "  1) Update commands, agents, and skills to latest version"
    Write-Host "  q) Quit"
    Write-Host ""
    $choice = Read-Host "Choice [1]"
    if (-not $choice) { $choice = "1" }
    switch ($choice) {
        "1" { Install-Skills; Write-Ok "Updated to latest version" }
        default { Write-Host "No changes made."; exit 0 }
    }

} elseif ($hasOpencode -and $hasConfig) {
    # OpenCode + config exist, skills missing/partial
    Write-Bold "OpenCode and provider config detected."
    Write-Host "  Your opencode.json will not be touched."
    Write-Host ""
    Write-Host "  1) Install commands, agents, and skills  (recommended)"
    Write-Host "  2) Update commands, agents, and skills   (overwrites existing)"
    Write-Host "  q) Quit"
    Write-Host ""
    $choice = Read-Host "Choice [1]"
    if (-not $choice) { $choice = "1" }
    switch ($choice) {
        { $_ -in "1","2" } { Install-Skills }
        default { Write-Host "No changes made."; exit 0 }
    }

} elseif ($hasOpencode -and -not $hasConfig) {
    # OpenCode installed, no provider config
    Write-Bold "OpenCode is installed but no provider is configured."
    Write-Host ""
    Write-Host "  1) Configure Ollama connection + install commands/agents/skills"
    Write-Host "  2) Install commands/agents/skills only  (you'll configure the provider yourself)"
    Write-Host "  q) Quit"
    Write-Host ""
    $choice = Read-Host "Choice [1]"
    if (-not $choice) { $choice = "1" }
    switch ($choice) {
        "1" { Configure-Ollama; Install-Skills }
        "2" { Install-Skills }
        default { Write-Host "No changes made."; exit 0 }
    }

} else {
    # OpenCode not installed
    Write-Bold "OpenCode not found."
    Write-Host ""
    Write-Host "  1) Full setup  — install OpenCode + configure Ollama + install commands/agents/skills"
    Write-Host "  2) Skills only — install commands/agents/skills (you handle OpenCode and provider)"
    Write-Host "  q) Quit"
    Write-Host ""
    $choice = Read-Host "Choice [1]"
    if (-not $choice) { $choice = "1" }
    switch ($choice) {
        "1" { Install-OpenCode; Configure-Ollama; Install-Skills }
        "2" { Install-Skills }
        default { Write-Host "No changes made."; exit 0 }
    }
}

Print-NextSteps
