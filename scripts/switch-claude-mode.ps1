#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Switch between Claude Code paid account and Antigravity proxy (free Google accounts)

.DESCRIPTION
    This script helps you switch between two modes:
    - 'paid': Use your Claude Code account (Anthropic API)
    - 'free': Use Antigravity proxy with your Google accounts

.PARAMETER Mode
    The mode to switch to: 'paid' or 'free'

.EXAMPLE
    .\switch-claude-mode.ps1 paid
    .\switch-claude-mode.ps1 free
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('paid', 'free')]
    [string]$Mode,

    [Parameter(Mandatory=$false)]
    [string]$SettingsPath = "$env:USERPROFILE\.claude\settings.json"
)

# Ensure settings directory exists
$settingsDir = Split-Path -Parent $SettingsPath
if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

# Backup current settings
$backupPath = "$SettingsPath.backup"
if (Test-Path $SettingsPath) {
    Write-Host "[INFO] Backing up settings..." -ForegroundColor Gray
    Copy-Item $SettingsPath $backupPath -Force
    Write-Host "       Backup saved to: $backupPath" -ForegroundColor DarkGray
}

# Load existing settings if they exist
$existingSettings = $null
if (Test-Path $SettingsPath) {
    try {
        $existingSettings = Get-Content $SettingsPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "[WARN] Could not parse existing settings, creating new config" -ForegroundColor Yellow
    }
}

if ($Mode -eq 'paid') {
    Write-Host "[INFO] Switching to PAID mode (Claude Code account)..." -ForegroundColor Cyan

    # Preserve existing settings, only modify env section
    if ($existingSettings) {
        $settings = $existingSettings | ConvertTo-Json -Depth 10 | ConvertFrom-Json  # Deep copy
        $settings.env = @{}
    } else {
        # No existing settings - create new
        $settings = @{
            env = @{}
        }
    }
    
    # Clear proxy environment variables for this session
    Remove-Item Env:\ANTHROPIC_BASE_URL -ErrorAction SilentlyContinue
    Remove-Item Env:\ANTHROPIC_AUTH_TOKEN -ErrorAction SilentlyContinue
    
    Write-Host "[OK] Switched to PAID mode" -ForegroundColor Green
    Write-Host "     Using: Anthropic API (your Claude Code account)" -ForegroundColor Gray
    Write-Host "     You'll be prompted to login when you run 'claude'" -ForegroundColor Gray
    
} elseif ($Mode -eq 'free') {
    Write-Host "[INFO] Switching to FREE mode (Google accounts via proxy)..." -ForegroundColor Cyan

    # Preserve existing settings, only modify env section
    if ($existingSettings) {
        $settings = $existingSettings | ConvertTo-Json -Depth 10 | ConvertFrom-Json  # Deep copy
    } else {
        # No existing settings - create new
        $settings = @{ env = @{} }
    }

    # Configure proxy settings
    $settings.env = @{
        ANTHROPIC_AUTH_TOKEN = "test"
        ANTHROPIC_BASE_URL = "http://localhost:8081"
        ANTHROPIC_MODEL = "claude-sonnet-4-5"
        ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-4-5"
        ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4-5"
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "gemini-3-flash"
        CLAUDE_CODE_SUBAGENT_MODEL = "claude-sonnet-4-5"
    }
    
    # Set proxy environment variables for this session
    $env:ANTHROPIC_BASE_URL = 'http://localhost:8081'
    $env:ANTHROPIC_AUTH_TOKEN = 'test'
    
    # Check if proxy is running and fetch accounts
    try {
        Write-Host "       Checking proxy status..." -ForegroundColor Gray
        $response = Invoke-WebRequest -Uri "http://localhost:8081/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        Write-Host "[OK] Proxy server is running" -ForegroundColor Green

        # Try to fetch accounts to display them
        try {
            $accountsResponse = Invoke-WebRequest -Uri "http://localhost:8081/account-limits?format=json" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($accountsResponse) {
                $accountsData = $accountsResponse.Content | ConvertFrom-Json
                $accounts = $accountsData.accounts
                if ($accounts) {
                    Write-Host "   Connected Accounts:" -ForegroundColor Gray
                    foreach ($acc in $accounts) {
                        Write-Host "    • $($acc.email)" -ForegroundColor White
                    }
                } else {
                     Write-Host "   Accounts: (None detected)" -ForegroundColor Gray
                }
            }
        } catch {
            Write-Host "   Accounts: (Use 'check-usage' to see details)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "[WARN] Proxy server is NOT running!" -ForegroundColor Yellow
        Write-Host "       Start it with: start-proxy" -ForegroundColor Cyan
        Write-Host "       (or set `$env:PORT='8081' and run 'antigravity-claude-proxy start')" -ForegroundColor DarkGray
    }
    
    Write-Host "[OK] Switched to FREE mode" -ForegroundColor Green
    Write-Host "     Using: Antigravity proxy (Google accounts)" -ForegroundColor Gray
}

# Save settings
$settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding utf8

Write-Host ""
Write-Host "[TIP] Restart your terminal or run '. `$PROFILE' to reload environment" -ForegroundColor Yellow
Write-Host "      Then run 'claude' to start Claude Code in $Mode mode" -ForegroundColor Yellow
