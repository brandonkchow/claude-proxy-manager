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
    [string]$Mode
)

$settingsPath = "$env:USERPROFILE\.claude\settings.json"

# Backup current settings
$backupPath = "$env:USERPROFILE\.claude\settings.backup.json"
if (Test-Path $settingsPath) {
    Copy-Item $settingsPath $backupPath -Force
}

if ($Mode -eq 'paid') {
    Write-Host "🔄 Switching to PAID mode (Claude Code account)..." -ForegroundColor Cyan
    
    # Remove proxy settings - use default Anthropic API
    $settings = @{
        env = @{}
    }
    
    # Clear proxy environment variables for this session
    Remove-Item Env:\ANTHROPIC_BASE_URL -ErrorAction SilentlyContinue
    Remove-Item Env:\ANTHROPIC_AUTH_TOKEN -ErrorAction SilentlyContinue
    
    Write-Host "✅ Switched to PAID mode" -ForegroundColor Green
    Write-Host "   Using: Anthropic API (your Claude Code account)" -ForegroundColor Gray
    Write-Host "   You'll be prompted to login when you run 'claude'" -ForegroundColor Gray
    
} elseif ($Mode -eq 'free') {
    Write-Host "🔄 Switching to FREE mode (Google accounts via proxy)..." -ForegroundColor Cyan
    
    # Configure proxy settings
    $settings = @{
        env = @{
            ANTHROPIC_AUTH_TOKEN = "test"
            ANTHROPIC_BASE_URL = "http://localhost:8081"
            ANTHROPIC_MODEL = "claude-sonnet-4-5"
            ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-4-5"
            ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4-5"
            ANTHROPIC_DEFAULT_HAIKU_MODEL = "gemini-3-flash"
            CLAUDE_CODE_SUBAGENT_MODEL = "claude-sonnet-4-5"
        }
    }
    
    # Set proxy environment variables for this session
    $env:ANTHROPIC_BASE_URL = 'http://localhost:8081'
    $env:ANTHROPIC_AUTH_TOKEN = 'test'
    
    # Check if proxy is running
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8081/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        Write-Host "✅ Proxy server is running" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Proxy server is NOT running!" -ForegroundColor Yellow
        Write-Host "   Start it with: `$env:PORT = '8081'; antigravity-claude-proxy start" -ForegroundColor Gray
    }
    
    Write-Host "✅ Switched to FREE mode" -ForegroundColor Green
    Write-Host "   Using: Antigravity proxy (Google accounts)" -ForegroundColor Gray
    Write-Host "   Accounts: (Use 'check-usage' to see details)" -ForegroundColor Gray
}

# Save settings
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding utf8

Write-Host ""
Write-Host "💡 Tip: Restart your terminal or run '. `$PROFILE' to reload environment" -ForegroundColor Yellow
Write-Host "   Then run 'claude' to start Claude Code in $Mode mode" -ForegroundColor Yellow
