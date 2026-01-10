# Claude Proxy Manager - Enhanced PowerShell Profile Functions
# Source the priority functions
. "$env:USERPROFILE\.claude\claude-proxy-manager\scripts\priority-functions.ps1"

# Claude Mode Switching Functions
function Use-ClaudePaid {
    param()
    & "$env:USERPROFILE\.claude\switch-claude-mode.ps1" paid
    Write-Host "`nReloading profile..." -ForegroundColor Cyan
    . $PROFILE
}

function Use-ClaudeFree {
    param()
    & "$env:USERPROFILE\.claude\switch-claude-mode.ps1" free
    Write-Host "`nReloading profile..." -ForegroundColor Cyan
    . $PROFILE
}

function Start-AntigravityProxy {
    param()
    Write-Host "Starting Antigravity proxy..." -ForegroundColor Cyan
    $env:PORT = '8081'
    antigravity-claude-proxy start
}

function Get-ClaudeMode {
    param()
    $settingsPath = "$env:USERPROFILE\.claude\settings.json"
    
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $baseUrl = $settings.env.ANTHROPIC_BASE_URL
        
        Write-Host "`nCurrent Claude Configuration:" -ForegroundColor Cyan
        
        if ($baseUrl -eq "http://localhost:8081") {
            Write-Host "   Mode: FREE (Antigravity Proxy)" -ForegroundColor Green
            Write-Host "   Using: Google accounts" -ForegroundColor Gray
            
            try {
                $null = Invoke-WebRequest -Uri "http://localhost:8081/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
                Write-Host "   Proxy: Running" -ForegroundColor Green
            } catch {
                Write-Host "   Proxy: Not Running" -ForegroundColor Red
                Write-Host "   Start with: start-proxy" -ForegroundColor Yellow
            }
        } else {
            Write-Host "   Mode: PAID (Claude Code Account)" -ForegroundColor Blue
            Write-Host "   Using: Anthropic API" -ForegroundColor Gray
        }
    } else {
        Write-Host "   No configuration found" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Check-ClaudeUsage {
    param()
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   CLAUDE USAGE OVERVIEW" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Load priority configuration if it exists
    $priorityPath = "$env:USERPROFILE\.claude\priority.json"
    $hasPriority = Test-Path $priorityPath
    $priority = if ($hasPriority) { Get-Content $priorityPath -Raw | ConvertFrom-Json } else { $null }
    
    if ($hasPriority) {
        Write-Host "Account Priority Order:" -ForegroundColor Cyan
        $index = 1
        foreach ($account in $priority.priority) {
            if (-not $account.enabled) { continue }
            
            Write-Host "[$index] " -NoNewline -ForegroundColor White
            
            if ($account.type -eq "claude-code") {
                Write-Host "PAID Claude Code Account" -ForegroundColor Blue
                Write-Host "    Status: " -NoNewline
                
                $settingsPath = "$env:USERPROFILE\.claude\settings.json"
                if (Test-Path $settingsPath) {
                    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
                    $baseUrl = $settings.env.ANTHROPIC_BASE_URL
                    
                    if ([string]::IsNullOrEmpty($baseUrl)) {
                        Write-Host "ACTIVE (Currently in use)" -ForegroundColor Green
                    } else {
                        Write-Host "Available (Switch with: claude-paid)" -ForegroundColor Yellow
                    }
                }
                Write-Host "    Note: Check usage at https://console.anthropic.com/settings/limits" -ForegroundColor Gray
                
            } elseif ($account.type -eq "antigravity") {
                Write-Host "FREE Antigravity - $($account.email)" -ForegroundColor Green
                
                try {
                    $limitsResponse = Invoke-WebRequest -Uri "http://localhost:8081/account-limits?format=json" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
                    $limits = $limitsResponse.Content | ConvertFrom-Json
                    $accountData = $limits.accounts | Where-Object { $_.email -eq $account.email }
                    
                    if ($accountData) {
                        $claude = $accountData.limits.'claude-sonnet-4-5'
                        $cRem = if ($claude -and $claude.remaining -ne "N/A" -and $claude.remaining -ne $null) { $claude.remaining } else { "0% (Exhausted)" }
                        $cReset = if ($claude -and $claude.resetTime) { 
                            try { (Get-Date $claude.resetTime).ToLocalTime().ToString("g") } catch { $claude.resetTime }
                        } else { "" }
                        Write-Host "    Claude (Sonnet 4.5): $cRem" -ForegroundColor $(if ($cRem -ne "0%" -and $cRem -ne "0" -and $cRem -ne "0% (Exhausted)") { "Green" } else { "Red" }) -NoNewline
                        if ($cReset) { Write-Host " (Resets: $cReset)" -ForegroundColor Gray } else { Write-Host "" }
                        
                        $gemini = $accountData.limits.'gemini-3-flash'
                        $gRem = if ($gemini -and $gemini.remaining -ne "N/A" -and $gemini.remaining -ne $null) { $gemini.remaining } else { "0% (Exhausted)" }
                        $gReset = if ($gemini -and $gemini.resetTime) { 
                            try { (Get-Date $gemini.resetTime).ToLocalTime().ToString("g") } catch { $gemini.resetTime }
                        } else { "" }
                        Write-Host "    Gemini (Flash 3):    $gRem" -ForegroundColor $(if ($gRem -ne "0%" -and $gRem -ne "0" -and $gRem -ne "0% (Exhausted)") { "Green" } else { "Red" }) -NoNewline
                        if ($gReset) { Write-Host " (Resets: $gReset)" -ForegroundColor Gray } else { Write-Host "" }
                    }
                } catch {
                    Write-Host "    Proxy not running" -ForegroundColor Yellow
                }
            }
            
            Write-Host ""
            $index++
        }
        
        Write-Host "Fallback: Claude -> Gemini (automatic)" -ForegroundColor Cyan
        Write-Host "`nChange priority: set-priority" -ForegroundColor Gray
        
    } else {
        # Fallback to old display if no priority config
        Write-Host "[!] Priority configuration not found or incomplete" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Run this command to set up account detection:" -ForegroundColor Cyan
        Write-Host "  init-priority" -ForegroundColor White
        Write-Host ""
        Write-Host "This will auto-detect:" -ForegroundColor Gray
        Write-Host "  - Your paid Claude Code account" -ForegroundColor Gray
        Write-Host "  - Your free Antigravity/Google accounts" -ForegroundColor Gray
        Write-Host "  - Configure priority order" -ForegroundColor Gray
    }
    
    Write-Host "`n========================================`n" -ForegroundColor Cyan
}

function Show-ClaudeHelp {
    param(
        [string]$Command  # Optional: show help for specific command
    )

    if ($Command) {
        # Show detailed help for specific command
        switch ($Command.ToLower()) {
            "claude-paid" {
                Write-Host "`nCommand: claude-paid" -ForegroundColor Cyan
                Write-Host "Switches to PAID mode (Claude Code account)" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  claude-paid" -ForegroundColor Gray
                Write-Host "`nWhat it does:" -ForegroundColor Yellow
                Write-Host "  - Updates ~/.claude/settings.json to use Anthropic API" -ForegroundColor Gray
                Write-Host "  - Removes proxy configuration" -ForegroundColor Gray
                Write-Host "  - Reloads PowerShell profile" -ForegroundColor Gray
            }
            "claude-free" {
                Write-Host "`nCommand: claude-free" -ForegroundColor Cyan
                Write-Host "Switches to FREE mode (Antigravity proxy)" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  claude-free" -ForegroundColor Gray
                Write-Host "`nWhat it does:" -ForegroundColor Yellow
                Write-Host "  - Updates ~/.claude/settings.json to use proxy at localhost:8081" -ForegroundColor Gray
                Write-Host "  - Starts proxy if not running" -ForegroundColor Gray
                Write-Host "  - Uses your Google accounts via Antigravity" -ForegroundColor Gray
            }
            "dual-sessions" {
                Write-Host "`nCommand: dual-sessions" -ForegroundColor Cyan
                Write-Host "Starts TWO HappyCoder sessions (FREE and PAID) for mobile access" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  dual-sessions                          # Basic usage (foreground)" -ForegroundColor Gray
                Write-Host "  dual-sessions -SessionName 'MyProject' # Custom name" -ForegroundColor Gray
                Write-Host "  dual-sessions -NoSymlinks              # Disable symlinks" -ForegroundColor Gray
                Write-Host "  dual-sessions -UseDaemon               # PERSISTENT MODE" -ForegroundColor Green
                Write-Host "`nWhat it does:" -ForegroundColor Yellow
                Write-Host "  - Creates symlinked directories (ProjectName-FREE and ProjectName-PAID)" -ForegroundColor Gray
                Write-Host "  - Opens two PowerShell windows with color coding" -ForegroundColor Gray
                Write-Host "    * GREEN window = FREE mode (Antigravity)" -ForegroundColor Gray
                Write-Host "    * BLUE window = PAID mode (Claude Code)" -ForegroundColor Gray
                Write-Host "  - Displays QR codes for HappyCoder mobile app" -ForegroundColor Gray
                Write-Host "`nPersistent Mode (-UseDaemon):" -ForegroundColor Yellow
                Write-Host "  Sessions survive terminal restarts and computer reboots!" -ForegroundColor Green
                Write-Host "  - Automatically starts daemon if not running" -ForegroundColor Gray
                Write-Host "  - One-time QR code scan, permanent mobile access" -ForegroundColor Gray
                Write-Host "  - Sessions reconnect automatically on mobile app" -ForegroundColor Gray
                Write-Host "`nIn HappyCoder app:" -ForegroundColor Yellow
                Write-Host "  You'll see two distinct sessions you can switch between!" -ForegroundColor Green
            }
            "check-usage" {
                Write-Host "`nCommand: check-usage" -ForegroundColor Cyan
                Write-Host "Displays usage quotas for all accounts" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  check-usage" -ForegroundColor Gray
                Write-Host "`nShows:" -ForegroundColor Yellow
                Write-Host "  - Current account priority order" -ForegroundColor Gray
                Write-Host "  - Claude/Gemini quota remaining for each Google account" -ForegroundColor Gray
                Write-Host "  - Reset times for quotas" -ForegroundColor Gray
            }
            "check-proxy-update" {
                Write-Host "`nCommand: check-proxy-update" -ForegroundColor Cyan
                Write-Host "Checks for updates to antigravity-claude-proxy" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  check-proxy-update" -ForegroundColor Gray
                Write-Host "`nWhat it does:" -ForegroundColor Yellow
                Write-Host "  - Compares installed version with latest npm version" -ForegroundColor Gray
                Write-Host "  - Fetches release notes from GitHub" -ForegroundColor Gray
                Write-Host "  - Prompts to update if newer version available" -ForegroundColor Gray
                Write-Host "`nNote:" -ForegroundColor Yellow
                Write-Host "  Runs automatically on profile load (cached 24 hours)" -ForegroundColor Gray
            }
            "init-priority" {
                Write-Host "`nCommand: init-priority" -ForegroundColor Cyan
                Write-Host "Initialize account priority configuration (first-time setup)" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  init-priority" -ForegroundColor Gray
                Write-Host "`nWhat it does:" -ForegroundColor Yellow
                Write-Host "  - Auto-detects your Claude Code account" -ForegroundColor Gray
                Write-Host "  - Auto-detects Antigravity/Google accounts from proxy" -ForegroundColor Gray
                Write-Host "  - Creates ~/.claude/priority.json configuration" -ForegroundColor Gray
                Write-Host "  - Prompts for default priority order (antigravity-first or claude-first)" -ForegroundColor Gray
                Write-Host "`nNote:" -ForegroundColor Yellow
                Write-Host "  This runs automatically on profile load if priority.json is missing" -ForegroundColor Gray
                Write-Host "  You can run it manually to re-detect accounts" -ForegroundColor Gray
            }
            "get-priority" {
                Write-Host "`nCommand: get-priority" -ForegroundColor Cyan
                Write-Host "View current account priority order" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  get-priority" -ForegroundColor Gray
                Write-Host "`nShows:" -ForegroundColor Yellow
                Write-Host "  - Priority order of all accounts (1st = highest priority)" -ForegroundColor Gray
                Write-Host "  - Enabled/disabled status for each account" -ForegroundColor Gray
                Write-Host "  - Account types (claude-code or antigravity)" -ForegroundColor Gray
                Write-Host "`nExample output:" -ForegroundColor Yellow
                Write-Host "  [1] Antigravity - user@gmail.com (enabled)" -ForegroundColor Gray
                Write-Host "  [2] Claude Code Account (enabled)" -ForegroundColor Gray
            }
            "set-priority" {
                Write-Host "`nCommand: set-priority" -ForegroundColor Cyan
                Write-Host "Change account priority order interactively" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  set-priority" -ForegroundColor Gray
                Write-Host "`nWhat it does:" -ForegroundColor Yellow
                Write-Host "  - Shows current priority order" -ForegroundColor Gray
                Write-Host "  - Prompts to reorder accounts" -ForegroundColor Gray
                Write-Host "  - Prompts to enable/disable specific accounts" -ForegroundColor Gray
                Write-Host "  - Saves updated configuration to priority.json" -ForegroundColor Gray
                Write-Host "`nUse cases:" -ForegroundColor Yellow
                Write-Host "  - Put free accounts first to preserve paid quota" -ForegroundColor Gray
                Write-Host "  - Put paid account first for better performance" -ForegroundColor Gray
                Write-Host "  - Disable exhausted accounts temporarily" -ForegroundColor Gray
            }
            "claude-update" {
                Write-Host "`nCommand: claude-update" -ForegroundColor Cyan
                Write-Host "Update Claude Proxy Manager to the latest version" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  claude-update" -ForegroundColor Gray
                Write-Host "`nWhat it does:" -ForegroundColor Yellow
                Write-Host "  - Detects if you have the repo cloned locally" -ForegroundColor Gray
                Write-Host "  - If yes: Syncs from repo to installed location" -ForegroundColor Gray
                Write-Host "  - If no: Downloads latest from GitHub" -ForegroundColor Gray
                Write-Host "  - Updates all scripts and config files" -ForegroundColor Gray
                Write-Host "`nWhen to use:" -ForegroundColor Yellow
                Write-Host "  - After pulling latest changes from GitHub" -ForegroundColor Gray
                Write-Host "  - When you see update notifications" -ForegroundColor Gray
                Write-Host "  - To sync your installed scripts with repo changes" -ForegroundColor Gray
                Write-Host "`nNote:" -ForegroundColor Yellow
                Write-Host "  After running, reload profile with: . `$PROFILE" -ForegroundColor Gray
            }
            "daemon-start" {
                Write-Host "`nCommand: daemon-start" -ForegroundColor Cyan
                Write-Host "Start the happy daemon for persistent HappyCoder sessions" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  daemon-start" -ForegroundColor Gray
                Write-Host "`nWhat it does:" -ForegroundColor Yellow
                Write-Host "  - Checks if daemon is already running" -ForegroundColor Gray
                Write-Host "  - Ensures antigravity proxy is running (for FREE mode)" -ForegroundColor Gray
                Write-Host "  - Starts happy daemon as background service" -ForegroundColor Gray
                Write-Host "  - Sessions will persist across terminal restarts and reboots" -ForegroundColor Gray
                Write-Host "`nAfter starting daemon:" -ForegroundColor Yellow
                Write-Host "  - Run: dual-sessions -UseDaemon  (for persistent sessions)" -ForegroundColor Cyan
                Write-Host "  - Sessions survive even if you close terminal windows" -ForegroundColor Gray
                Write-Host "  - Sessions reconnect automatically on mobile" -ForegroundColor Gray
            }
            "daemon-stop" {
                Write-Host "`nCommand: daemon-stop" -ForegroundColor Cyan
                Write-Host "Stop the happy daemon" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  daemon-stop" -ForegroundColor Gray
                Write-Host "`nWhat it does:" -ForegroundColor Yellow
                Write-Host "  - Stops the daemon background service" -ForegroundColor Gray
                Write-Host "  - Sessions remain active on relay server" -ForegroundColor Gray
                Write-Host "  - Sessions can reconnect when daemon restarts" -ForegroundColor Gray
                Write-Host "`nIMPORTANT:" -ForegroundColor Yellow
                Write-Host "  Your sessions are NOT lost when daemon stops!" -ForegroundColor Green
                Write-Host "  They persist on the happy-server relay" -ForegroundColor Gray
            }
            "daemon-status" {
                Write-Host "`nCommand: daemon-status" -ForegroundColor Cyan
                Write-Host "Check if happy daemon is running and show session count" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  daemon-status" -ForegroundColor Gray
                Write-Host "  `$status = daemon-status  # Returns object" -ForegroundColor Gray
                Write-Host "`nShows:" -ForegroundColor Yellow
                Write-Host "  - Whether daemon is running" -ForegroundColor Gray
                Write-Host "  - Number of active sessions" -ForegroundColor Gray
                Write-Host "  - Number of happy processes" -ForegroundColor Gray
            }
            "daemon-restart" {
                Write-Host "`nCommand: daemon-restart" -ForegroundColor Cyan
                Write-Host "Restart the happy daemon (sessions persist)" -ForegroundColor White
                Write-Host "`nUsage:" -ForegroundColor Yellow
                Write-Host "  daemon-restart" -ForegroundColor Gray
                Write-Host "`nWhat it does:" -ForegroundColor Yellow
                Write-Host "  - Stops the daemon" -ForegroundColor Gray
                Write-Host "  - Waits 2 seconds" -ForegroundColor Gray
                Write-Host "  - Starts the daemon again" -ForegroundColor Gray
                Write-Host "  - Sessions survive the restart" -ForegroundColor Gray
                Write-Host "`nWhen to use:" -ForegroundColor Yellow
                Write-Host "  - After updating happy-coder: npm update -g happy-coder" -ForegroundColor Cyan
                Write-Host "  - If daemon seems unresponsive" -ForegroundColor Gray
                Write-Host "  - To apply daemon configuration changes" -ForegroundColor Gray
            }
            default {
                Write-Host "`nCommand not found: $Command" -ForegroundColor Red
                Write-Host "Run 'claude-help' to see all available commands" -ForegroundColor Yellow
            }
        }
        Write-Host ""
        return
    }

    # Show general help
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  CLAUDE PROXY MANAGER - HELP" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "MODE SWITCHING" -ForegroundColor Yellow
    Write-Host "  claude-paid       Switch to PAID Claude Code account" -ForegroundColor White
    Write-Host "  claude-free       Switch to FREE Antigravity proxy" -ForegroundColor White
    Write-Host "  claude-mode       Show current mode and configuration" -ForegroundColor White
    Write-Host ""

    Write-Host "USAGE & MONITORING" -ForegroundColor Yellow
    Write-Host "  check-usage          View quotas for all accounts" -ForegroundColor White
    Write-Host "  start-proxy          Manually start Antigravity proxy" -ForegroundColor White
    Write-Host "  check-proxy-update   Check for proxy updates" -ForegroundColor White
    Write-Host ""

    Write-Host "PRIORITY MANAGEMENT" -ForegroundColor Yellow
    Write-Host "  init-priority     Initialize account priority configuration" -ForegroundColor White
    Write-Host "  get-priority      View current priority order" -ForegroundColor White
    Write-Host "  set-priority      Change account priority order" -ForegroundColor White
    Write-Host ""

    Write-Host "HAPPYCODER (MOBILE ACCESS)" -ForegroundColor Yellow
    Write-Host "  happy-free        Start HappyCoder with Antigravity" -ForegroundColor White
    Write-Host "  happy-paid        Start HappyCoder with Claude Code" -ForegroundColor White
    Write-Host "  dual-sessions     Start BOTH sessions (RECOMMENDED)" -ForegroundColor Green
    Write-Host "                    Creates distinct FREE/PAID sessions for mobile" -ForegroundColor Gray
    Write-Host ""

    Write-Host "HELP & DOCUMENTATION" -ForegroundColor Yellow
    Write-Host "  claude-help              Show this help message" -ForegroundColor White
    Write-Host "  claude-help <command>    Show detailed help for a command" -ForegroundColor White
    Write-Host "                           Example: claude-help dual-sessions" -ForegroundColor Gray
    Write-Host ""

    Write-Host "UPDATES & MAINTENANCE" -ForegroundColor Yellow
    Write-Host "  claude-update         Update to latest version" -ForegroundColor White
    Write-Host "                        Syncs from repo or downloads from GitHub" -ForegroundColor Gray
    Write-Host ""

    Write-Host "PERSISTENT SESSIONS (Happy Daemon)" -ForegroundColor Yellow
    Write-Host "  daemon-start          Start daemon (sessions survive restarts)" -ForegroundColor White
    Write-Host "  daemon-stop           Stop daemon (sessions persist on relay)" -ForegroundColor White
    Write-Host "  daemon-status         Check daemon health and session count" -ForegroundColor White
    Write-Host "  daemon-restart        Restart daemon (safe - sessions survive)" -ForegroundColor White
    Write-Host "  dual-sessions -UseDaemon   Start persistent dual sessions" -ForegroundColor Green
    Write-Host ""

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "QUICK START:" -ForegroundColor Green
    Write-Host "  1. Run 'check-usage' to see your accounts" -ForegroundColor Gray
    Write-Host "  2. Run 'claude-free' or 'claude-paid' to switch modes" -ForegroundColor Gray
    Write-Host "  3. For mobile: Run 'dual-sessions' and scan QR codes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Documentation: https://github.com/brandonkchow/claude-proxy-manager" -ForegroundColor Cyan
    Write-Host ""
}

# Aliases for convenience (all lowercase)
Set-Alias -Name claude-paid -Value Use-ClaudePaid
Set-Alias -Name claude-free -Value Use-ClaudeFree
Set-Alias -Name claude-mode -Value Get-ClaudeMode
Set-Alias -Name check-usage -Value Check-ClaudeUsage
Set-Alias -Name start-proxy -Value Start-AntigravityProxy
Set-Alias -Name init-priority -Value Initialize-ClaudePriority
Set-Alias -Name get-priority -Value Get-ClaudePriority
Set-Alias -Name set-priority -Value Set-ClaudePriority
Set-Alias -Name claude-help -Value Show-ClaudeHelp

# HappyCoder Dual-Session Functions
function Start-HappyFree {
    Write-Host "Starting HappyCoder with Antigravity proxy..." -ForegroundColor Cyan

    # Ensure Proxy is Running
    $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue
    if (-not $proxyRunning) {
        Write-Host "Starting Antigravity Proxy in background..." -ForegroundColor Yellow
        Start-Job -ScriptBlock {
            $env:PORT = '8081'
            antigravity-claude-proxy start
        } | Out-Null

        # Wait for proxy to be ready
        Write-Host "Waiting for proxy to start..." -ForegroundColor Yellow
        $maxAttempts = 15
        $attempt = 0
        do {
            Start-Sleep -Seconds 1
            $attempt++
            $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue
            if ($proxyRunning) {
                Write-Host "Proxy is ready!" -ForegroundColor Green
                break
            }
        } while ($attempt -lt $maxAttempts)

        if (-not $proxyRunning) {
            Write-Host "Warning: Proxy may not have started properly" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Proxy is already running." -ForegroundColor Green
    }

    # Start HappyCoder
    Write-Host "Launching HappyCoder... Scan the QR code with your mobile app!" -ForegroundColor Cyan
    Write-Host ""
    happy --claude-env ANTHROPIC_AUTH_TOKEN=test --claude-env ANTHROPIC_BASE_URL=http://localhost:8081
}

function Start-HappyPaid {
    Write-Host "Starting HappyCoder with paid Claude Code..." -ForegroundColor Cyan
    Write-Host "Scan the QR code below with your mobile app!" -ForegroundColor Cyan
    Write-Host ""
    happy
}

function Start-DualSessions {
    param(
        [string]$WorkingDirectory = (Get-Location).Path,
        [string]$SessionName,  # Custom session name (defaults to directory name)
        [switch]$NoSymlinks,   # Disable symlinks (NOT recommended - sessions will have identical names)
        [switch]$UseDaemon     # Use daemon mode for persistent sessions (survive restarts)
    )

    Write-Host "Setting up dual HappyCoder sessions with QR codes..." -ForegroundColor Cyan
    Write-Host "  Working directory: $WorkingDirectory" -ForegroundColor Gray

    # Check daemon mode
    if ($UseDaemon) {
        Write-Host "  Mode: PERSISTENT (daemon mode - sessions survive restarts)" -ForegroundColor Magenta

        # Ensure daemon is running
        $daemonStatus = Get-HappyDaemonStatus
        if (-not $daemonStatus.Running) {
            Write-Host "  [!] Daemon not running - starting now..." -ForegroundColor Yellow
            Start-HappyDaemon
            Start-Sleep -Seconds 2
        } else {
            Write-Host "  [OK] Daemon already running ($($daemonStatus.SessionCount) active sessions)" -ForegroundColor Green
        }
    } else {
        Write-Host "  Mode: Standard (foreground - sessions end when windows close)" -ForegroundColor Gray
        Write-Host "  Tip: Use -UseDaemon for persistent sessions" -ForegroundColor DarkGray
    }

    # Determine base session name
    $baseName = if ($SessionName) { $SessionName } else { Split-Path -Leaf $WorkingDirectory }

    # Create symlinks for unique session names (DEFAULT behavior)
    $freeDir = $WorkingDirectory
    $paidDir = $WorkingDirectory
    $useSymlinks = -not $NoSymlinks

    if ($useSymlinks) {
        $parentDir = Split-Path -Parent $WorkingDirectory
        $freeDir = Join-Path $parentDir "$baseName-FREE"
        $paidDir = Join-Path $parentDir "$baseName-PAID"

        # Create symlinks if they don't exist
        if (-not (Test-Path $freeDir)) {
            Write-Host "  Creating FREE symlink: $freeDir" -ForegroundColor Gray
            try {
                New-Item -ItemType SymbolicLink -Path $freeDir -Target $WorkingDirectory -ErrorAction Stop | Out-Null
                Write-Host "    [OK] FREE symlink created" -ForegroundColor Green
            } catch {
                Write-Host "    [!] Failed to create symlink (may need admin rights)" -ForegroundColor Yellow
                Write-Host "        Falling back to same directory" -ForegroundColor Yellow
                $freeDir = $WorkingDirectory
                $paidDir = $WorkingDirectory
                $useSymlinks = $false
            }
        } else {
            Write-Host "    [OK] FREE symlink already exists" -ForegroundColor Green
        }

        if ($useSymlinks -and -not (Test-Path $paidDir)) {
            Write-Host "  Creating PAID symlink: $paidDir" -ForegroundColor Gray
            try {
                New-Item -ItemType SymbolicLink -Path $paidDir -Target $WorkingDirectory -ErrorAction Stop | Out-Null
                Write-Host "    [OK] PAID symlink created" -ForegroundColor Green
            } catch {
                Write-Host "    [!] Failed to create symlink (may need admin rights)" -ForegroundColor Yellow
                Write-Host "        Falling back to same directory" -ForegroundColor Yellow
                $freeDir = $WorkingDirectory
                $paidDir = $WorkingDirectory
                $useSymlinks = $false
            }
        } elseif ($useSymlinks) {
            Write-Host "    [OK] PAID symlink already exists" -ForegroundColor Green
        }

        if ($useSymlinks) {
            Write-Host "`n  Sessions will appear in HappyCoder app as:" -ForegroundColor Cyan
            Write-Host "    - $baseName-FREE (Antigravity)" -ForegroundColor Green
            Write-Host "    - $baseName-PAID (Claude Code)" -ForegroundColor Blue
        }
    }

    if (-not $useSymlinks) {
        Write-Host "`n  [WARNING] Both sessions use the same directory!" -ForegroundColor Yellow
        Write-Host "    They will appear identical in the HappyCoder app." -ForegroundColor Yellow
        Write-Host "    Use window colors (GREEN/BLUE) to identify them." -ForegroundColor Yellow
    }

    # Ensure proxy is running first (for FREE mode)
    Write-Host "  Ensuring Antigravity proxy is running..." -ForegroundColor Cyan
    $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue
    if (-not $proxyRunning) {
        Write-Host "  Starting proxy in background..." -ForegroundColor Yellow
        Start-Job -ScriptBlock {
            $env:PORT = '8081'
            antigravity-claude-proxy start
        } | Out-Null

        # Wait for proxy
        $maxAttempts = 15
        $attempt = 0
        do {
            Start-Sleep -Seconds 1
            $attempt++
            $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue
            if ($proxyRunning) {
                Write-Host "  Proxy ready!" -ForegroundColor Green
                break
            }
        } while ($attempt -lt $maxAttempts)
    } else {
        Write-Host "  Proxy already running!" -ForegroundColor Green
    }

    # Open FREE mode window with GREEN theme
    Write-Host "`n  Opening FREE mode window (Antigravity)..." -ForegroundColor Yellow
    $sessionLabel = if ($useSymlinks) { "$baseName-FREE" } else { "$baseName [GREEN]" }
    Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
Set-Location '$freeDir'
`$Host.UI.RawUI.WindowTitle = 'FREE - $sessionLabel'
`$Host.UI.RawUI.BackgroundColor = 'DarkGreen'
`$Host.UI.RawUI.ForegroundColor = 'White'
Clear-Host
Write-Host ''
Write-Host '  ========================================================' -ForegroundColor Green
Write-Host '  ||                                                    ||' -ForegroundColor Green
Write-Host '  ||        [FREE] MODE - ANTIGRAVITY PROXY            ||' -ForegroundColor Green
Write-Host '  ||                                                    ||' -ForegroundColor Green
Write-Host '  ========================================================' -ForegroundColor Green
Write-Host ''
Write-Host '  Session: $sessionLabel' -ForegroundColor Yellow
Write-Host '  Directory: $freeDir' -ForegroundColor Gray
Write-Host ''
Write-Host '  SCAN QR CODE BELOW WITH HAPPYCODER APP' -ForegroundColor Yellow
Write-Host '  --> This session uses FREE Google accounts' -ForegroundColor White
Write-Host ''
happy --claude-env ANTHROPIC_AUTH_TOKEN=test --claude-env ANTHROPIC_BASE_URL=http://localhost:8081
"@

    # Small delay to ensure windows don't overlap QR codes
    Start-Sleep -Milliseconds 500

    # Open PAID mode window with BLUE theme
    Write-Host "  Opening PAID mode window (Claude Code)..." -ForegroundColor Yellow
    $sessionLabel = if ($useSymlinks) { "$baseName-PAID" } else { "$baseName [BLUE]" }
    Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
Set-Location '$paidDir'
`$Host.UI.RawUI.WindowTitle = 'PAID - $sessionLabel'
`$Host.UI.RawUI.BackgroundColor = 'DarkBlue'
`$Host.UI.RawUI.ForegroundColor = 'White'
Clear-Host
Write-Host ''
Write-Host '  ========================================================' -ForegroundColor Blue
Write-Host '  ||                                                    ||' -ForegroundColor Blue
Write-Host '  ||          [PAID] MODE - CLAUDE CODE                ||' -ForegroundColor Blue
Write-Host '  ||                                                    ||' -ForegroundColor Blue
Write-Host '  ========================================================' -ForegroundColor Blue
Write-Host ''
Write-Host '  Session: $sessionLabel' -ForegroundColor Yellow
Write-Host '  Directory: $paidDir' -ForegroundColor Gray
Write-Host ''
Write-Host '  SCAN QR CODE BELOW WITH HAPPYCODER APP' -ForegroundColor Yellow
Write-Host '  --> This session uses PAID Claude Code account' -ForegroundColor White
Write-Host ''
happy
"@

    Write-Host "`n  SUCCESS: Two HappyCoder windows opened!" -ForegroundColor Green
    Write-Host ""
    if ($useSymlinks) {
        Write-Host "  In HappyCoder mobile app, you'll see:" -ForegroundColor Cyan
        Write-Host "    [FREE] $baseName-FREE  <- Antigravity (free)" -ForegroundColor Green
        Write-Host "    [PAID] $baseName-PAID  <- Claude Code (paid)" -ForegroundColor Blue
    } else {
        Write-Host "  Look for window colors to identify sessions:" -ForegroundColor Cyan
        Write-Host "    Green background  = FREE mode (Antigravity)" -ForegroundColor Green
        Write-Host "    Blue background   = PAID mode (Claude Code)" -ForegroundColor Blue
    }
    Write-Host ""
    Write-Host "  Scan both QR codes to switch between sessions on mobile!" -ForegroundColor Yellow
}

Set-Alias -Name happy-free -Value Start-HappyFree
Set-Alias -Name happy-paid -Value Start-HappyPaid
Set-Alias -Name dual-sessions -Value Start-DualSessions

# ============================================
# Update Command - Keep scripts in sync
# ============================================

function Update-ClaudeProxyManager {
    <#
    .SYNOPSIS
        Updates Claude Proxy Manager scripts to latest version

    .DESCRIPTION
        Syncs scripts from repo (if available) or downloads from GitHub.
        Ensures your installed scripts match the latest version.
    #>

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  CLAUDE PROXY MANAGER UPDATE" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    $installDir = "$env:USERPROFILE\.claude\claude-proxy-manager"

    # Check if local repo exists
    $possibleRepoPaths = @(
        "C:\Users\$env:USERNAME\GitHub\claude-proxy-manager",
        "C:\Users\$env:USERNAME\github\claude-proxy-manager",
        "$env:USERPROFILE\GitHub\claude-proxy-manager",
        "$env:USERPROFILE\github\claude-proxy-manager",
        "$env:USERPROFILE\Documents\GitHub\claude-proxy-manager"
    )

    $repoPath = $null
    foreach ($path in $possibleRepoPaths) {
        if (Test-Path "$path\.git") {
            $repoPath = $path
            break
        }
    }

    if ($repoPath) {
        # SCENARIO A: Developer with local repo
        Write-Host "[Developer Mode] Updating from local repository..." -ForegroundColor Magenta
        Write-Host "  Repo location: $repoPath" -ForegroundColor Gray

        try {
            # Create directories if they don't exist
            New-Item -ItemType Directory -Path "$installDir\config" -Force | Out-Null
            New-Item -ItemType Directory -Path "$installDir\scripts" -Force | Out-Null

            # Copy config files
            Copy-Item "$repoPath\config\profile-snippet.ps1" "$installDir\config\" -Force
            Copy-Item "$repoPath\config\update-checker.ps1" "$installDir\config\" -Force -ErrorAction SilentlyContinue

            # Copy script files
            Copy-Item "$repoPath\scripts\priority-functions.ps1" "$installDir\scripts\" -Force
            Copy-Item "$repoPath\scripts\switch-claude-mode.ps1" "$installDir\scripts\" -Force

            Write-Host "`n[OK] Updated from local repository!" -ForegroundColor Green
            Write-Host "  Files synced to: $installDir" -ForegroundColor Gray
        } catch {
            Write-Host "`n[ERROR] Failed to copy files: $_" -ForegroundColor Red
            return
        }
    } else {
        # SCENARIO B: End user without local repo
        Write-Host "[End User Mode] Downloading latest from GitHub..." -ForegroundColor Cyan

        try {
            $tempZip = "$env:TEMP\claude-proxy-manager.zip"
            $tempExtract = "$env:TEMP\cpm-update"

            # Download latest release
            Write-Host "  Downloading..." -ForegroundColor Gray
            Invoke-WebRequest -Uri "https://github.com/brandonkchow/claude-proxy-manager/archive/refs/heads/main.zip" -OutFile $tempZip -UseBasicParsing

            # Extract
            Write-Host "  Extracting..." -ForegroundColor Gray
            Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

            # Create directories
            New-Item -ItemType Directory -Path "$installDir\config" -Force | Out-Null
            New-Item -ItemType Directory -Path "$installDir\scripts" -Force | Out-Null

            # Copy files
            Write-Host "  Installing files..." -ForegroundColor Gray
            $extractedPath = "$tempExtract\claude-proxy-manager-main"
            Copy-Item "$extractedPath\config\profile-snippet.ps1" "$installDir\config\" -Force
            Copy-Item "$extractedPath\config\update-checker.ps1" "$installDir\config\" -Force -ErrorAction SilentlyContinue
            Copy-Item "$extractedPath\scripts\priority-functions.ps1" "$installDir\scripts\" -Force
            Copy-Item "$extractedPath\scripts\switch-claude-mode.ps1" "$installDir\scripts\" -Force

            # Cleanup
            Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
            Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

            Write-Host "`n[OK] Updated from GitHub!" -ForegroundColor Green
            Write-Host "  Files installed to: $installDir" -ForegroundColor Gray
        } catch {
            Write-Host "`n[ERROR] Failed to download/install: $_" -ForegroundColor Red
            Write-Host "  Please check your internet connection and try again." -ForegroundColor Yellow
            return
        }
    }

    Write-Host "`nTo apply changes, reload your profile:" -ForegroundColor Yellow
    Write-Host "  . `$PROFILE" -ForegroundColor Cyan
    Write-Host "`n========================================`n" -ForegroundColor Cyan
}

Set-Alias -Name claude-update -Value Update-ClaudeProxyManager

# ============================================
# Happy Daemon Management - Persistent Sessions
# ============================================

function Get-HappyDaemonStatus {
    <#
    .SYNOPSIS
        Check if happy daemon is running and get session count

    .DESCRIPTION
        Parses output of 'happy daemon status' and returns structured info
    #>

    try {
        $output = happy daemon status 2>&1 | Out-String

        $status = @{
            Running = $false
            SessionCount = 0
            ProcessCount = 0
        }

        if ($output -match "Daemon is running") {
            $status.Running = $true
        }

        # Parse session count if available
        if ($output -match "(\d+) active sessions") {
            $status.SessionCount = [int]$Matches[1]
        }

        # Parse process count
        if ($output -match "(\d+) happy processes") {
            $status.ProcessCount = [int]$Matches[1]
        }

        return $status
    } catch {
        Write-Host "[ERROR] Failed to check daemon status: $_" -ForegroundColor Red
        return @{ Running = $false; SessionCount = 0; ProcessCount = 0 }
    }
}

function Start-HappyDaemon {
    <#
    .SYNOPSIS
        Start the happy daemon for persistent sessions

    .DESCRIPTION
        Starts the happy daemon as a background service.
        Sessions will persist across terminal restarts and reboots.
    #>

    Write-Host "`nStarting happy daemon..." -ForegroundColor Cyan

    # Check if already running
    $status = Get-HappyDaemonStatus
    if ($status.Running) {
        Write-Host "[INFO] Daemon is already running" -ForegroundColor Yellow
        Write-Host "  Active sessions: $($status.SessionCount)" -ForegroundColor Gray
        return
    }

    # Ensure antigravity proxy is running (needed for FREE mode)
    Write-Host "  Checking antigravity proxy..." -ForegroundColor Gray
    $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue

    if (-not $proxyRunning) {
        Write-Host "  [!] Antigravity proxy not running" -ForegroundColor Yellow
        Write-Host "  Starting proxy (needed for FREE mode sessions)..." -ForegroundColor Gray

        Start-Job -ScriptBlock {
            $env:PORT = '8081'
            antigravity-claude-proxy start
        } | Out-Null

        # Wait for proxy
        $maxAttempts = 15
        $attempt = 0
        do {
            Start-Sleep -Seconds 1
            $attempt++
            $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue
            if ($proxyRunning) {
                Write-Host "  [OK] Proxy ready" -ForegroundColor Green
                break
            }
        } while ($attempt -lt $maxAttempts)

        if (-not $proxyRunning) {
            Write-Host "  [!] Proxy failed to start - FREE mode sessions may not work" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [OK] Proxy already running" -ForegroundColor Green
    }

    # Start daemon
    try {
        Write-Host "  Starting daemon process..." -ForegroundColor Gray
        $output = happy daemon start 2>&1 | Out-String

        # Verify it started
        Start-Sleep -Seconds 2
        $status = Get-HappyDaemonStatus

        if ($status.Running) {
            Write-Host "`n[OK] Happy daemon started successfully!" -ForegroundColor Green
            Write-Host "  Sessions will now persist across terminal restarts" -ForegroundColor Gray
            Write-Host "  To start persistent dual sessions: dual-sessions -UseDaemon" -ForegroundColor Cyan
        } else {
            Write-Host "`n[ERROR] Daemon failed to start" -ForegroundColor Red
            Write-Host "  Output: $output" -ForegroundColor Gray
        }
    } catch {
        Write-Host "`n[ERROR] Failed to start daemon: $_" -ForegroundColor Red
    }
}

function Stop-HappyDaemon {
    <#
    .SYNOPSIS
        Stop the happy daemon

    .DESCRIPTION
        Stops the daemon process. Sessions will remain active on the relay server
        and can be reconnected when daemon restarts.
    #>

    Write-Host "`nStopping happy daemon..." -ForegroundColor Cyan
    Write-Host "  [INFO] Sessions will remain active on relay server" -ForegroundColor Gray

    # Check if running
    $status = Get-HappyDaemonStatus
    if (-not $status.Running) {
        Write-Host "[INFO] Daemon is not running" -ForegroundColor Yellow
        return
    }

    try {
        $output = happy daemon stop 2>&1 | Out-String
        Start-Sleep -Seconds 1

        # Verify it stopped
        $status = Get-HappyDaemonStatus
        if (-not $status.Running) {
            Write-Host "[OK] Daemon stopped" -ForegroundColor Green
            Write-Host "  Sessions are still active on relay server" -ForegroundColor Gray
        } else {
            Write-Host "[WARNING] Daemon may still be running" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERROR] Failed to stop daemon: $_" -ForegroundColor Red
    }
}

function Restart-HappyDaemon {
    <#
    .SYNOPSIS
        Restart the happy daemon

    .DESCRIPTION
        Stops and restarts the daemon. Sessions persist during restart.
        Use this after updating happy-coder npm package.
    #>

    Write-Host "`nRestarting happy daemon..." -ForegroundColor Cyan
    Write-Host "  [INFO] Sessions will remain active during restart" -ForegroundColor Gray

    Stop-HappyDaemon
    Start-Sleep -Seconds 2
    Start-HappyDaemon
}

# Aliases for daemon commands
Set-Alias -Name daemon-start -Value Start-HappyDaemon
Set-Alias -Name daemon-stop -Value Stop-HappyDaemon
Set-Alias -Name daemon-status -Value Get-HappyDaemonStatus
Set-Alias -Name daemon-restart -Value Restart-HappyDaemon

# Auto-initialize priority configuration if missing or incomplete
$priorityPath = "$env:USERPROFILE\.claude\priority.json"
if (-not (Test-Path $priorityPath)) {
    Write-Host "[INFO] Priority configuration not found. Auto-detecting accounts..." -ForegroundColor Yellow
    try {
        Initialize-ClaudePriority -DefaultPriority 'antigravity-first' -ErrorAction SilentlyContinue
        Write-Host "[OK] Priority configuration created automatically" -ForegroundColor Green
    } catch {
        # Silently fail - user can run init-priority manually
    }
} else {
    # Check if priority.json has Antigravity accounts
    try {
        $priorityConfig = Get-Content $priorityPath -Raw | ConvertFrom-Json
        $hasAntigravity = $priorityConfig.priority | Where-Object { $_.type -eq 'antigravity' }

        if (-not $hasAntigravity) {
            # Check if proxy is running with accounts
            try {
                $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
                if ($proxyRunning) {
                    $limitsResponse = Invoke-WebRequest -Uri "http://localhost:8081/account-limits?format=json" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
                    $limits = $limitsResponse.Content | ConvertFrom-Json

                    if ($limits.accounts -and $limits.accounts.Count -gt 0) {
                        Write-Host "[INFO] Antigravity accounts detected. Updating priority configuration..." -ForegroundColor Yellow
                        Initialize-ClaudePriority -DefaultPriority 'antigravity-first' -ErrorAction SilentlyContinue
                        Write-Host "[OK] Priority configuration updated" -ForegroundColor Green
                    }
                }
            } catch {
                # Silently fail - proxy might not be running
            }
        }
    } catch {
        # Silently fail - invalid priority.json, user can fix manually
    }
}

# Load update checker
. "$env:USERPROFILE\.claude\claude-proxy-manager\config\update-checker.ps1"

# Check for antigravity-claude-proxy updates (cached for 24 hours)
Check-AntigravityUpdate

# Show current mode on profile load
Get-ClaudeMode
