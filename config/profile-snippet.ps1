# Claude Proxy Manager - PowerShell Profile Functions
# Add this to your PowerShell profile: $PROFILE

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
                Write-Host "   Start with: Start-AntigravityProxy" -ForegroundColor Yellow
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
    
    Write-Host "[1] PAID Claude Code Account" -ForegroundColor Blue
    Write-Host "    Status: " -NoNewline
    
    $settingsPath = "$env:USERPROFILE\.claude\settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $baseUrl = $settings.env.ANTHROPIC_BASE_URL
        
        if ($baseUrl -eq "http://localhost:8081" -or [string]::IsNullOrEmpty($baseUrl)) {
            if ([string]::IsNullOrEmpty($baseUrl)) {
                Write-Host "ACTIVE (Currently in use)" -ForegroundColor Green
            } else {
                Write-Host "Available (Switch with: claude-paid)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Available (Switch with: claude-paid)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "    Note: Check usage at https://console.anthropic.com/settings/limits" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "[2] FREE Google Accounts (via Antigravity)" -ForegroundColor Green
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8081/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        Write-Host "    Proxy Status: " -NoNewline
        Write-Host "Running" -ForegroundColor Green
        
        try {
            $limitsResponse = Invoke-WebRequest -Uri "http://localhost:8081/account-limits?format=json" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            $limits = $limitsResponse.Content | ConvertFrom-Json
            
            Write-Host "`n    Account Quotas:" -ForegroundColor Cyan
            foreach ($account in $limits.accounts) {
                Write-Host "    - $($account.email)" -ForegroundColor White
                
                $claude = $account.limits.'claude-sonnet-4-5'
                $cRem = if ($claude -and $claude.remaining -ne "N/A" -and $claude.remaining -ne $null) { $claude.remaining } else { "0% (Exhausted)" }
                $cReset = if ($claude -and $claude.resetTime) { 
                    try { (Get-Date $claude.resetTime).ToLocalTime().ToString("g") } catch { $claude.resetTime }
                } else { "" }
                Write-Host "      Claude (Sonnet 4.5): $cRem" -ForegroundColor $(if ($cRem -ne "0%" -and $cRem -ne "0" -and $cRem -ne "0% (Exhausted)") { "Green" } else { "Red" }) -NoNewline
                if ($cReset) { Write-Host " (Resets: $cReset)" -ForegroundColor Gray } else { Write-Host "" }
                
                $gemini = $account.limits.'gemini-3-flash'
                $gRem = if ($gemini -and $gemini.remaining -ne "N/A" -and $gemini.remaining -ne $null) { $gemini.remaining } else { "0% (Exhausted)" }
                $gReset = if ($gemini -and $gemini.resetTime) { 
                    try { (Get-Date $gemini.resetTime).ToLocalTime().ToString("g") } catch { $gemini.resetTime }
                } else { "" }
                Write-Host "      Gemini (Flash 3):    $gRem" -ForegroundColor $(if ($gRem -ne "0%" -and $gRem -ne "0" -and $gRem -ne "0% (Exhausted)") { "Green" } else { "Red" }) -NoNewline
                if ($gReset) { Write-Host " (Resets: $gReset)" -ForegroundColor Gray } else { Write-Host "" }
            }
            
            Write-Host "`n    Fallback: " -NoNewline
            Write-Host "Claude -> Gemini (automatic)" -ForegroundColor Cyan
            
        } catch {
            Write-Host "`n    Could not fetch quota details" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "    Proxy Status: " -NoNewline
        Write-Host "Not Running" -ForegroundColor Red
        Write-Host "    Start with: start-proxy" -ForegroundColor Yellow
    }
    
    Write-Host "`n========================================`n" -ForegroundColor Cyan
}

# Aliases for convenience
Set-Alias -Name claude-paid -Value Use-ClaudePaid
Set-Alias -Name claude-free -Value Use-ClaudeFree
Set-Alias -Name claude-mode -Value Get-ClaudeMode
Set-Alias -Name check-usage -Value Check-ClaudeUsage
Set-Alias -Name start-proxy -Value Start-AntigravityProxy

# Show current mode on profile load
Get-ClaudeMode
