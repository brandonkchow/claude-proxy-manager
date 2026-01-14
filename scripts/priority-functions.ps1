# Claude Proxy Manager - Priority Management Functions
# These functions manage the account priority order

function Initialize-ClaudePriority {
    <#
    .SYNOPSIS
    Auto-detects accounts and creates initial priority configuration
    
    .DESCRIPTION
    Queries the Antigravity proxy and Claude Code authentication to discover
    available accounts and creates a priority.json configuration file.
    #>
    
    param(
        [Parameter()]
        [ValidateSet('claude-first', 'antigravity-first')]
        [string]$DefaultPriority = 'claude-first'
    )
    
    $priorityPath = "$env:USERPROFILE\.claude\priority.json"
    $priority = @{
        priority = @()
        currentMode = "auto"
        autoDetect = $true
    }
    
    Write-Host "Detecting available accounts..." -ForegroundColor Cyan
    
    # Detect Antigravity accounts
    $antigravityAccounts = @()
    try {
        # Fast check for proxy port
        $proxyRunning = $false
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $connect = $tcp.BeginConnect("localhost", 8081, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(100, $false)
            if ($tcp.Connected) {
                $tcp.EndConnect($connect)
                $tcp.Close()
                $proxyRunning = $true
            }
            $tcp.Dispose()
        } catch {}

        if ($proxyRunning) {
            $response = Invoke-RestMethod -Uri "http://localhost:8081/account-limits?format=json" -ErrorAction Stop
            foreach ($account in $response.accounts) {
                $antigravityAccounts += @{
                    name = "Antigravity - $($account.email)"
                    type = "antigravity"
                    email = $account.email
                    enabled = $true
                }
                Write-Host "  [OK] Found Antigravity account: $($account.email)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "  [!] Proxy not running or no accounts found" -ForegroundColor Yellow
    }
    
    # Detect Claude Code authentication
    $hasClaudeAuth = $false
    try {
        $claudeVersion = claude --version 2>$null
        $hasClaudeAuth = $claudeVersion -ne $null
    } catch {
        $hasClaudeAuth = $false
    }
    
    if ($hasClaudeAuth) {
        Write-Host "  [OK] Claude Code authenticated" -ForegroundColor Green
    }
    
    # Build priority list based on preference
    if ($DefaultPriority -eq 'antigravity-first') {
        # Antigravity accounts first
        $priority.priority += $antigravityAccounts
        if ($hasClaudeAuth) {
            $priority.priority += @{
                name = "Claude Code Paid"
                type = "claude-code"
                enabled = $true
            }
        }
    } else {
        # Claude Code first (default)
        if ($hasClaudeAuth) {
            $priority.priority += @{
                name = "Claude Code Paid"
                type = "claude-code"
                enabled = $true
            }
        }
        $priority.priority += $antigravityAccounts
    }
    
    # Save configuration
    $priority | ConvertTo-Json -Depth 10 | Set-Content $priorityPath -Encoding utf8
    Write-Host "`nPriority configuration created: $priorityPath" -ForegroundColor Green
    
    return $priority
}

function Get-ClaudePriority {
    <#
    .SYNOPSIS
    Shows the current account priority order
    #>
    param(
        [string]$PriorityConfigPath = "$env:USERPROFILE\.claude\priority.json"
    )

    $priorityPath = $PriorityConfigPath

    if (-not (Test-Path $priorityPath)) {
        Write-Host "No priority configuration found. Run Initialize-ClaudePriority first." -ForegroundColor Yellow
        return
    }

    $priority = Get-Content $priorityPath -Raw | ConvertFrom-Json
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   ACCOUNT PRIORITY ORDER" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    $index = 1
    foreach ($account in $priority.priority) {
        $status = if ($account.enabled) { "[ENABLED]" } else { "[DISABLED]" }
        $color = if ($account.enabled) { "Green" } else { "Gray" }
        
        Write-Host "$index. " -NoNewline -ForegroundColor White
        Write-Host "$status " -NoNewline -ForegroundColor $color
        Write-Host $account.name -ForegroundColor White
        
        if ($account.type -eq "antigravity") {
            Write-Host "   Email: $($account.email)" -ForegroundColor Gray
        }
        
        $index++
    }
    
    Write-Host "`n========================================`n" -ForegroundColor Cyan
    Write-Host "Mode: $($priority.currentMode)" -ForegroundColor Gray
}

function Set-ClaudePriority {
    <#
    .SYNOPSIS
    Interactively reorder account priority
    #>
    
    $priorityPath = "$env:USERPROFILE\.claude\priority.json"
    
    if (-not (Test-Path $priorityPath)) {
        Write-Host "No priority configuration found. Run Initialize-ClaudePriority first." -ForegroundColor Yellow
        return
    }
    
    $priority = Get-Content $priorityPath -Raw | ConvertFrom-Json
    
    Write-Host "`nCurrent Priority Order:" -ForegroundColor Cyan
    Get-ClaudePriority
    
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  1. Move Claude Code to first" -ForegroundColor White
    Write-Host "  2. Move Antigravity accounts to first" -ForegroundColor White
    Write-Host "  3. Enable/Disable specific account" -ForegroundColor White
    Write-Host "  4. Cancel" -ForegroundColor White
    
    $choice = Read-Host "`nEnter choice (1-4)"
    
    switch ($choice) {
        "1" {
            # Move Claude Code to first
            $claudeAccount = $priority.priority | Where-Object { $_.type -eq "claude-code" }
            $otherAccounts = $priority.priority | Where-Object { $_.type -ne "claude-code" }
            
            if ($claudeAccount) {
                $priority.priority = @($claudeAccount) + $otherAccounts
                $priority | ConvertTo-Json -Depth 10 | Set-Content $priorityPath -Encoding utf8
                Write-Host "`n[OK] Claude Code moved to first priority" -ForegroundColor Green
                Get-ClaudePriority
            } else {
                Write-Host "`n[X] No Claude Code account found" -ForegroundColor Red
            }
        }
        "2" {
            # Move Antigravity to first
            $antigravityAccounts = $priority.priority | Where-Object { $_.type -eq "antigravity" }
            $claudeAccount = $priority.priority | Where-Object { $_.type -eq "claude-code" }
            
            if ($antigravityAccounts) {
                $priority.priority = $antigravityAccounts + @($claudeAccount)
                $priority | ConvertTo-Json -Depth 10 | Set-Content $priorityPath -Encoding utf8
                Write-Host "`n[OK] Antigravity accounts moved to first priority" -ForegroundColor Green
                Get-ClaudePriority
            } else {
                Write-Host "`n[X] No Antigravity accounts found" -ForegroundColor Red
            }
        }
        "3" {
            # Enable/Disable account
            Write-Host "`nEnter account number to toggle:" -ForegroundColor Cyan
            $accountNum = Read-Host
            
            try {
                $index = [int]$accountNum - 1
                if ($index -ge 0 -and $index -lt $priority.priority.Count) {
                    $priority.priority[$index].enabled = -not $priority.priority[$index].enabled
                    $priority | ConvertTo-Json -Depth 10 | Set-Content $priorityPath -Encoding utf8
                    
                    $status = if ($priority.priority[$index].enabled) { "enabled" } else { "disabled" }
                    Write-Host "`n[OK] Account $($priority.priority[$index].name) $status" -ForegroundColor Green
                    Get-ClaudePriority
                } else {
                    Write-Host "`n[X] Invalid account number" -ForegroundColor Red
                }
            } catch {
                Write-Host "`n[X] Invalid input" -ForegroundColor Red
            }
        }
        "4" {
            Write-Host "`nCancelled" -ForegroundColor Yellow
        }
        default {
            Write-Host "`n[X] Invalid choice" -ForegroundColor Red
        }
    }
}
