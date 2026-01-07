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

# Step 9: Optional Remote Access Setup
Write-Host "`n[9/9] Remote Access Setup (Optional)" -ForegroundColor Cyan
Write-Host "  Set up SSH, tmux, and HappyCoder for mobile/remote access?" -ForegroundColor White

if (Prompt-YesNo "Install remote access tools?" $false) {
    
    # 9a: Enable Windows OpenSSH Server (with UAC elevation)
    Write-Host "`n  [9a] Checking OpenSSH Server..." -ForegroundColor Cyan
    
    try {
        $sshService = Get-WindowsCapability -Online -ErrorAction Stop | Where-Object Name -like 'OpenSSH.Server*'
        
        if ($sshService.State -ne "Installed") {
            Write-Host "  OpenSSH Server not installed. Requesting admin privileges..." -ForegroundColor Yellow
            
            # Create elevated script to install OpenSSH
            $elevatedScript = @"
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}
Write-Host 'OpenSSH Server installed successfully!' -ForegroundColor Green
pause
"@
            
            # Save to temp file
            $tempScript = "$env:TEMP\install-openssh.ps1"
            $elevatedScript | Set-Content $tempScript
            
            # Run with elevation
            try {
                Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" -Verb RunAs -Wait
                Write-Host "  [OK] OpenSSH Server installed" -ForegroundColor Green
            } catch {
                Write-Host "  [!] User cancelled elevation or installation failed" -ForegroundColor Yellow
            }
            
            # Cleanup
            Remove-Item $tempScript -ErrorAction SilentlyContinue
        } else {
            Write-Host "  [OK] OpenSSH Server already installed" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [!] Cannot check OpenSSH (requires admin privileges)" -ForegroundColor Yellow
        Write-Host "      Attempting to install with elevation..." -ForegroundColor Cyan
        
        # Try elevation anyway
        $elevatedScript = @"
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}
Write-Host 'OpenSSH Server installed successfully!' -ForegroundColor Green
pause
"@
        $tempScript = "$env:TEMP\install-openssh.ps1"
        $elevatedScript | Set-Content $tempScript
        
        try {
            Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" -Verb RunAs -Wait
            Write-Host "  [OK] OpenSSH Server installed" -ForegroundColor Green
        } catch {
            Write-Host "  [!] Installation cancelled or failed" -ForegroundColor Yellow
        }
        
        Remove-Item $tempScript -ErrorAction SilentlyContinue
    }
    
    # 9b: Install Chocolatey (if needed) and tmux
    Write-Host "`n  [9b] Checking tmux..." -ForegroundColor Cyan
    try {
        $tmuxVersion = tmux -V 2>$null
        if ($tmuxVersion) {
            Write-Host "  [OK] tmux already installed" -ForegroundColor Green
        } else {
            throw "Not found"
        }
    } catch {
        Write-Host "  [!] tmux not found" -ForegroundColor Yellow
        
        # Check if Chocolatey is installed
        try {
            $chocoVersion = choco --version 2>$null
            if ($chocoVersion) {
                Write-Host "  [OK] Chocolatey detected, installing tmux..." -ForegroundColor Cyan
                choco install tmux -y
                Write-Host "  [OK] tmux installed" -ForegroundColor Green
            } else {
                throw "Chocolatey not found"
            }
        } catch {
            Write-Host "  [!] Chocolatey not installed" -ForegroundColor Yellow
            Write-Host "  Installing Chocolatey..." -ForegroundColor Cyan
            
            # Install Chocolatey with elevation
            $chocoInstallScript = @"
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install tmux -y
Write-Host 'Chocolatey and tmux installed successfully!' -ForegroundColor Green
pause
"@
            $tempScript = "$env:TEMP\install-choco-tmux.ps1"
            $chocoInstallScript | Set-Content $tempScript
            
            try {
                Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" -Verb RunAs -Wait
                Write-Host "  [OK] Chocolatey and tmux installed" -ForegroundColor Green
            } catch {
                Write-Host "  [!] Installation cancelled or failed" -ForegroundColor Yellow
                Write-Host "      You can install manually later:" -ForegroundColor Gray
                Write-Host "      1. Install Chocolatey: https://chocolatey.org/install" -ForegroundColor Gray
                Write-Host "      2. Run: choco install tmux" -ForegroundColor Gray
            }
            
            Remove-Item $tempScript -ErrorAction SilentlyContinue
        }
    }
    
    # 9c: Install HappyCoder CLI
    Write-Host "`n  [9c] Checking HappyCoder CLI..." -ForegroundColor Cyan
    try {
        $happyVersion = happy --version 2>$null
        if ($happyVersion) {
            Write-Host "  [OK] HappyCoder CLI already installed" -ForegroundColor Green
        } else {
            throw "Not found"
        }
    } catch {
        Write-Host "  Installing HappyCoder CLI..." -ForegroundColor Cyan
        npm install -g happy-coder
        Write-Host "  [OK] HappyCoder CLI installed" -ForegroundColor Green
    }
    
    # 9d: Create dual-session aliases
    Write-Host "`n  [9d] Creating dual-session aliases..." -ForegroundColor Cyan
    
    $remoteAliases = @"

# HappyCoder Dual-Session Setup (for easy mode switching)
function Start-HappyFree {
    Write-Host "Starting HappyCoder with Antigravity proxy..." -ForegroundColor Cyan
    happy --claude-env ANTHROPIC_AUTH_TOKEN=test --claude-env ANTHROPIC_BASE_URL=http://localhost:8081
}

function Start-HappyPaid {
    Write-Host "Starting HappyCoder with paid Claude Code..." -ForegroundColor Cyan
    happy
}

# Dual tmux session setup
function Start-DualSessions {
    Write-Host "Setting up dual tmux sessions..." -ForegroundColor Cyan
    
    # Start FREE session
    Write-Host "  Creating FREE session (happy-free)..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "tmux new -s happy-free 'powershell -NoExit -Command `"start-proxy; Start-HappyFree`"'"
    Start-Sleep -Seconds 2
    
    # Start PAID session
    Write-Host "  Creating PAID session (happy-paid)..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "tmux new -s happy-paid 'powershell -NoExit -Command `"claude-paid; Start-HappyPaid`"'"
    
    Write-Host "`n  [OK] Dual sessions created!" -ForegroundColor Green
    Write-Host "      - happy-free: Antigravity proxy" -ForegroundColor Gray
    Write-Host "      - happy-paid: Claude Code paid" -ForegroundColor Gray
    Write-Host "`n  Scan both QR codes in HappyCoder app to switch between them!" -ForegroundColor Cyan
}

Set-Alias -Name happy-free -Value Start-HappyFree
Set-Alias -Name happy-paid -Value Start-HappyPaid
Set-Alias -Name dual-sessions -Value Start-DualSessions
"@
    
    # Add to profile if not already there
    $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($profileContent -notmatch "HappyCoder Dual-Session") {
        Add-Content -Path $profilePath -Value $remoteAliases
        Write-Host "  [OK] Dual-session aliases added to profile" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Dual-session aliases already configured" -ForegroundColor Green
    }
    
    Write-Host "`n  [OK] Remote access setup complete!" -ForegroundColor Green
    Write-Host "`n  New commands available:" -ForegroundColor Cyan
    Write-Host "    happy-free       Start HappyCoder with Antigravity" -ForegroundColor White
    Write-Host "    happy-paid       Start HappyCoder with Claude Code" -ForegroundColor White
    Write-Host "    dual-sessions    Start both sessions for easy switching" -ForegroundColor White
    
} else {
    Write-Host "  [SKIP] Remote access setup skipped" -ForegroundColor Yellow
    Write-Host "  You can run this later with: .\scripts\install-remote.ps1" -ForegroundColor Gray
}

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

