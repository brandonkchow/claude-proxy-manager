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
    Write-Host "Starting Antigravity proxy with Claude->Gemini fallback enabled..." -ForegroundColor Cyan
    $env:PORT = '8081'
    antigravity-claude-proxy start --fallback
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
        Write-Host "[1] PAID Claude Code Account" -ForegroundColor Blue
        Write-Host "    Note: Check usage at https://console.anthropic.com/settings/limits`n" -ForegroundColor Gray
        
        Write-Host "[2] FREE Google Accounts (via Antigravity)" -ForegroundColor Green
        Write-Host "    Run: init-priority to set up priority order" -ForegroundColor Yellow
    }
    
    Write-Host "`n========================================`n" -ForegroundColor Cyan
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

# HappyCoder Dual-Session Functions
function Start-HappyFree {
    Write-Host "Starting HappyCoder with Antigravity proxy..." -ForegroundColor Cyan

    # Ensure Proxy is Running
    $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue
    if (-not $proxyRunning) {
        Write-Host "Starting Antigravity Proxy in background..." -ForegroundColor Yellow
        Start-Job -ScriptBlock {
            $env:PORT = '8081'
            antigravity-claude-proxy start --fallback
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
        [switch]$UseSymlinks  # Creates symlinks for distinct session names in HappyCoder app
    )

    Write-Host "Setting up dual HappyCoder sessions with QR codes..." -ForegroundColor Cyan
    Write-Host "  Working directory: $WorkingDirectory" -ForegroundColor Gray

    # Create symlinks for unique session names (optional)
    $freeDir = $WorkingDirectory
    $paidDir = $WorkingDirectory

    if ($UseSymlinks) {
        $baseName = Split-Path -Leaf $WorkingDirectory
        $parentDir = Split-Path -Parent $WorkingDirectory
        $freeDir = Join-Path $parentDir "$baseName-FREE"
        $paidDir = Join-Path $parentDir "$baseName-PAID"

        # Create symlinks if they don't exist
        if (-not (Test-Path $freeDir)) {
            Write-Host "  Creating FREE symlink: $freeDir" -ForegroundColor Gray
            New-Item -ItemType SymbolicLink -Path $freeDir -Target $WorkingDirectory -ErrorAction SilentlyContinue | Out-Null
        }
        if (-not (Test-Path $paidDir)) {
            Write-Host "  Creating PAID symlink: $paidDir" -ForegroundColor Gray
            New-Item -ItemType SymbolicLink -Path $paidDir -Target $WorkingDirectory -ErrorAction SilentlyContinue | Out-Null
        }

        Write-Host "  Sessions will appear as '$baseName-FREE' and '$baseName-PAID' in HappyCoder app" -ForegroundColor Green
    }

    # Ensure proxy is running first (for FREE mode)
    Write-Host "  Ensuring Antigravity proxy is running..." -ForegroundColor Cyan
    $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue
    if (-not $proxyRunning) {
        Write-Host "  Starting proxy in background..." -ForegroundColor Yellow
        Start-Job -ScriptBlock {
            $env:PORT = '8081'
            antigravity-claude-proxy start --fallback
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
    Write-Host "  Opening FREE mode window (Antigravity)..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
Set-Location '$freeDir'
`$Host.UI.RawUI.WindowTitle = '[FREE] HappyCoder - Antigravity Proxy'
Write-Host '========================================================' -ForegroundColor Green
Write-Host '                                                        ' -ForegroundColor Green
Write-Host '            FREE MODE - ANTIGRAVITY PROXY               ' -ForegroundColor Green
Write-Host '                                                        ' -ForegroundColor Green
Write-Host '========================================================' -ForegroundColor Green
Write-Host ''
Write-Host 'Scan the QR code below with HappyCoder mobile app' -ForegroundColor Yellow
Write-Host 'Directory: $freeDir' -ForegroundColor Gray
Write-Host ''
happy --claude-env ANTHROPIC_AUTH_TOKEN=test --claude-env ANTHROPIC_BASE_URL=http://localhost:8081
"@

    # Open PAID mode window with BLUE theme
    Write-Host "  Opening PAID mode window (Claude Code)..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
Set-Location '$paidDir'
`$Host.UI.RawUI.WindowTitle = '[PAID] HappyCoder - Claude Code'
Write-Host '========================================================' -ForegroundColor Blue
Write-Host '                                                        ' -ForegroundColor Blue
Write-Host '              PAID MODE - CLAUDE CODE                   ' -ForegroundColor Blue
Write-Host '                                                        ' -ForegroundColor Blue
Write-Host '========================================================' -ForegroundColor Blue
Write-Host ''
Write-Host 'Scan the QR code below with HappyCoder mobile app' -ForegroundColor Yellow
Write-Host 'Directory: $paidDir' -ForegroundColor Gray
Write-Host ''
happy
"@

    Write-Host "`n  [OK] Two HappyCoder windows opened!" -ForegroundColor Green
    Write-Host "  GREEN window = FREE mode (Antigravity)" -ForegroundColor Green
    Write-Host "  BLUE window = PAID mode (Claude Code)" -ForegroundColor Blue
    Write-Host "`n  Scan the QR codes in each window with your mobile app" -ForegroundColor Cyan
    Write-Host "  You can now switch between FREE and PAID modes in HappyCoder!" -ForegroundColor Green
}

Set-Alias -Name happy-free -Value Start-HappyFree
Set-Alias -Name happy-paid -Value Start-HappyPaid
Set-Alias -Name dual-sessions -Value Start-DualSessions

# Show current mode on profile load
Get-ClaudeMode
