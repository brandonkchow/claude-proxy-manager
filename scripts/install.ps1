# Claude Proxy Manager - Installer
# One-click installation script with smart detection and configuration

param(
    [switch]$SkipPrereqs,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   CLAUDE PROXY MANAGER INSTALLER" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Helper function for user prompts
function Prompt-YesNo {
    param([string]$Question, [bool]$DefaultYes = $true)
    
    if ($NonInteractive) { return $DefaultYes }
    
    $default = if ($DefaultYes) { "Y" } else { "N" }
    $prompt = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    
    $response = Read-Host "$Question $prompt"
    if ([string]::IsNullOrWhiteSpace($response)) { return $DefaultYes }
    return $response -match "^[Yy]"
}

# Step 1: Check Prerequisites
Write-Host "[1/8] Checking prerequisites..." -ForegroundColor Cyan

# Check Node.js
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "  [OK] Node.js $nodeVersion detected" -ForegroundColor Green
    } else {
        throw "Node.js not found"
    }
} catch {
    Write-Host "  [X] Node.js not found" -ForegroundColor Red
    Write-Host "`nPlease install Node.js 18+ from: https://nodejs.org/" -ForegroundColor Yellow
    Write-Host "Then re-run this installer.`n" -ForegroundColor Yellow
    exit 1
}

# Check npm
try {
    $npmVersion = npm --version 2>$null
    if ($npmVersion) {
        Write-Host "  [OK] npm $npmVersion detected" -ForegroundColor Green
    }
} catch {
    Write-Host "  [X] npm not found (should come with Node.js)" -ForegroundColor Red
    exit 1
}

# Step 2: Check/Install Claude Code CLI
Write-Host "`n[2/8] Checking Claude Code CLI..." -ForegroundColor Cyan

try {
    $claudeVersion = claude --version 2>$null
    if ($claudeVersion) {
        Write-Host "  [OK] Claude Code CLI detected" -ForegroundColor Green
        $hasClaudeCLI = $true
    } else {
        throw "Not found"
    }
} catch {
    Write-Host "  [!] Claude Code CLI not found" -ForegroundColor Yellow
    
    if (Prompt-YesNo "Install Claude Code CLI now?") {
        Write-Host "  Installing @anthropic-ai/claude-code..." -ForegroundColor Cyan
        npm install -g @anthropic-ai/claude-code
        Write-Host "  [OK] Claude Code CLI installed" -ForegroundColor Green
        $hasClaudeCLI = $true
    } else {
        Write-Host "  [SKIP] Claude Code CLI installation skipped" -ForegroundColor Yellow
        $hasClaudeCLI = $false
    }
}

# Step 3: Check/Install antigravity-claude-proxy
Write-Host "`n[3/8] Checking antigravity-claude-proxy..." -ForegroundColor Cyan

try {
    $proxyVersion = antigravity-claude-proxy --version 2>$null
    if ($proxyVersion) {
        Write-Host "  [OK] antigravity-claude-proxy $proxyVersion detected" -ForegroundColor Green
        $hasProxy = $true
    } else {
        throw "Not found"
    }
} catch {
    Write-Host "  [!] antigravity-claude-proxy not found" -ForegroundColor Yellow
    
    if (Prompt-YesNo "Install antigravity-claude-proxy now?") {
        Write-Host "  Installing antigravity-claude-proxy..." -ForegroundColor Cyan
        npm install -g antigravity-claude-proxy
        Write-Host "  [OK] antigravity-claude-proxy installed" -ForegroundColor Green
        $hasProxy = $true
    } else {
        Write-Host "  [SKIP] Proxy installation skipped" -ForegroundColor Yellow
        $hasProxy = $false
    }
}

# Step 4: Detect Accounts
Write-Host "`n[4/8] Detecting accounts..." -ForegroundColor Cyan

$antigravityAccounts = @()
if ($hasProxy) {
    try {
        $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($proxyRunning) {
            $response = Invoke-RestMethod -Uri "http://localhost:8081/account-limits?format=json" -ErrorAction Stop
            foreach ($account in $response.accounts) {
                $antigravityAccounts += $account.email
                Write-Host "  [OK] Found Antigravity account: $($account.email)" -ForegroundColor Green
            }
        } else {
            Write-Host "  [!] Proxy not running - Antigravity accounts not detected" -ForegroundColor Yellow
            Write-Host "      You can add accounts later with: antigravity-claude-proxy accounts add" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [!] Could not detect Antigravity accounts" -ForegroundColor Yellow
    }
}

$hasClaudeAuth = $false
if ($hasClaudeCLI) {
    try {
        $claudeTest = claude --version 2>$null
        $hasClaudeAuth = $claudeTest -ne $null
        if ($hasClaudeAuth) {
            Write-Host "  [OK] Claude Code authenticated" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [!] Claude Code not authenticated" -ForegroundColor Yellow
        Write-Host "      You can login later with: claude /login" -ForegroundColor Gray
    }
}

# Check if we have at least one account
if (-not $hasClaudeAuth -and $antigravityAccounts.Count -eq 0) {
    Write-Host "`n  [!] No accounts detected!" -ForegroundColor Yellow
    Write-Host "      You need at least one of:" -ForegroundColor Yellow
    Write-Host "        - Claude Code authentication (claude /login)" -ForegroundColor Gray
    Write-Host "        - Antigravity account (antigravity-claude-proxy accounts add)" -ForegroundColor Gray
    Write-Host "`n      Please set up an account and re-run the installer.`n" -ForegroundColor Yellow
    exit 1
}

# Step 5: Choose Priority
Write-Host "`n[5/8] Configuring account priority..." -ForegroundColor Cyan

$defaultPriority = "claude-first"
if ($antigravityAccounts.Count -gt 0 -and $hasClaudeAuth) {
    Write-Host "`n  Which account should be used first?" -ForegroundColor White
    Write-Host "    1. Claude Code (paid account) - Recommended for most users" -ForegroundColor White
    Write-Host "    2. Antigravity (free accounts) - Better for avoiding thinking model conflicts" -ForegroundColor White
    
    if (-not $NonInteractive) {
        $choice = Read-Host "`n  Enter choice (1 or 2)"
        if ($choice -eq "2") {
            $defaultPriority = "antigravity-first"
        }
    }
}

Write-Host "  Priority: $defaultPriority" -ForegroundColor Green

# Step 6: Install Files
Write-Host "`n[6/8] Installing files..." -ForegroundColor Cyan

$installDir = "$env:USERPROFILE\.claude\claude-proxy-manager"
New-Item -ItemType Directory -Path "$installDir\scripts" -Force | Out-Null

# Copy scripts (assuming we're running from the repo)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Copy-Item "$scriptDir\priority-functions.ps1" "$installDir\scripts\" -Force
Copy-Item "$scriptDir\switch-claude-mode.ps1" "$installDir\scripts\" -Force

Write-Host "  [OK] Files installed to $installDir" -ForegroundColor Green

# Step 7: Configure PowerShell Profile
Write-Host "`n[7/8] Configuring PowerShell profile..." -ForegroundColor Cyan

$profilePath = $PROFILE
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Write-Host "  [OK] Created PowerShell profile" -ForegroundColor Green
}

# Check if already configured
$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notmatch "claude-proxy-manager") {
    $snippet = @"

# Claude Proxy Manager
. "$installDir\scripts\priority-functions.ps1"
"@
    Add-Content -Path $profilePath -Value $snippet
    Write-Host "  [OK] PowerShell profile updated" -ForegroundColor Green
} else {
    Write-Host "  [OK] PowerShell profile already configured" -ForegroundColor Green
}

# Step 8: Initialize Priority
Write-Host "`n[8/8] Initializing priority configuration..." -ForegroundColor Cyan

. "$installDir\scripts\priority-functions.ps1"
Initialize-ClaudePriority -DefaultPriority $defaultPriority | Out-Null

Write-Host "  [OK] Priority configuration created" -ForegroundColor Green

# Success!
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Reload your PowerShell profile: . `$PROFILE" -ForegroundColor White
Write-Host "  2. Check your setup: check-usage" -ForegroundColor White
Write-Host "  3. View priority order: get-priority" -ForegroundColor White
Write-Host "`nAvailable commands:" -ForegroundColor Cyan
Write-Host "  claude-paid      Switch to paid Claude Code" -ForegroundColor White
Write-Host "  claude-free      Switch to free Antigravity" -ForegroundColor White
Write-Host "  check-usage      View all account quotas" -ForegroundColor White
Write-Host "  set-priority     Change account priority" -ForegroundColor White
Write-Host "  start-proxy      Start Antigravity proxy`n" -ForegroundColor White
