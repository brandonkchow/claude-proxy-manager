# Happy Daemon Startup Script
# Auto-starts happy daemon on Windows login via Task Scheduler
# Location: ~/.claude/claude-proxy-manager/scripts/daemon-startup.ps1

param(
    [switch]$Force  # Force start even if disabled in config
)

$ErrorActionPreference = "SilentlyContinue"

# Logging
$logPath = "$env:USERPROFILE\.claude\claude-proxy-manager\daemon-startup.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Log {
    param([string]$Message)
    "$timestamp - $Message" | Out-File -FilePath $logPath -Append
    Write-Host $Message
}

Write-Log "=== Happy Daemon Startup ==="

# Check configuration
$configPath = "$env:USERPROFILE\.claude\claude-proxy-manager\daemon-config.json"

if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Log "Config loaded: AutoStart=$($config.autoStartDaemon), Mode=$($config.autoStartMode)"

        if (-not $config.autoStartDaemon -and -not $Force) {
            Write-Log "Auto-start disabled in config. Exiting."
            exit 0
        }
    } catch {
        Write-Log "Failed to parse config: $_"
        # Continue anyway - default to starting daemon
        $config = @{ autoStartMode = "none" }
    }
} else {
    Write-Log "No config found - will start daemon without sessions"
    $config = @{ autoStartMode = "none" }
}

# Check if daemon already running
try {
    $daemonCheck = happy daemon status 2>&1 | Out-String
    if ($daemonCheck -match "Daemon is running") {
        Write-Log "Daemon already running. Exiting."
        exit 0
    }
} catch {
    Write-Log "Error checking daemon status: $_"
}

# Ensure antigravity proxy is running (needed for FREE mode)
Write-Log "Checking antigravity proxy..."
$proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue

if (-not $proxyRunning) {
    Write-Log "Proxy not running - starting..."

    # Start proxy in background
    Start-Job -ScriptBlock {
        $env:PORT = '8081'
        antigravity-claude-proxy start 2>&1 | Out-File "$env:USERPROFILE\.claude\claude-proxy-manager\proxy-startup.log"
    } | Out-Null

    # Wait for proxy (max 30 seconds)
    $maxAttempts = 30
    $attempt = 0
    do {
        Start-Sleep -Seconds 1
        $attempt++
        $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue

        if ($proxyRunning) {
            Write-Log "Proxy started successfully"
            break
        }
    } while ($attempt -lt $maxAttempts)

    if (-not $proxyRunning) {
        Write-Log "WARNING: Proxy failed to start after 30s - FREE mode sessions may not work"
    }
} else {
    Write-Log "Proxy already running"
}

# Start happy daemon
Write-Log "Starting happy daemon..."
try {
    $output = happy daemon start 2>&1 | Out-String
    Write-Log "Daemon start output: $output"

    # Verify it started
    Start-Sleep -Seconds 2
    $daemonCheck = happy daemon status 2>&1 | Out-String

    if ($daemonCheck -match "Daemon is running") {
        Write-Log "SUCCESS: Daemon started successfully"

        # Update state file
        $statePath = "$env:USERPROFILE\.claude\claude-proxy-manager\daemon-state.json"
        $state = @{
            daemonRunning = $true
            lastStartTime = (Get-Date).ToString('o')
            startedBy = "auto-startup"
        }
        $state | ConvertTo-Json | Set-Content $statePath -Encoding utf8

        # Auto-start sessions based on config
        if ($config.autoStartMode -and $config.autoStartMode -ne "none") {
            Write-Log "Auto-starting sessions: $($config.autoStartMode)"

            $workDir = if ($config.defaultWorkingDirectory) { $config.defaultWorkingDirectory } else { $env:USERPROFILE }

            switch ($config.autoStartMode) {
                "dual" {
                    Write-Log "Starting dual sessions in: $workDir"
                    # Source profile functions
                    . "$env:USERPROFILE\.claude\claude-proxy-manager\config\profile-snippet.ps1"
                    Start-DualSessions -WorkingDirectory $workDir -UseDaemon
                }
                "free" {
                    Write-Log "Starting FREE session in: $workDir"
                    # Escape single quotes to prevent command injection
                    $safeWorkDir = $workDir -replace "'", "''"
                    Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
Set-Location '$safeWorkDir'
`$Host.UI.RawUI.WindowTitle = 'HappyCoder - FREE (Antigravity)'
Write-Host 'Starting FREE mode session...' -ForegroundColor Green
happy --claude-env ANTHROPIC_AUTH_TOKEN=test --claude-env ANTHROPIC_BASE_URL=http://localhost:8081
"@
                }
                "paid" {
                    Write-Log "Starting PAID session in: $workDir"
                    # Escape single quotes to prevent command injection
                    $safeWorkDir = $workDir -replace "'", "''"
                    Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
Set-Location '$safeWorkDir'
`$Host.UI.RawUI.WindowTitle = 'HappyCoder - PAID (Claude Code)'
Write-Host 'Starting PAID mode session...' -ForegroundColor Blue
happy
"@
                }
            }
        }

        exit 0
    } else {
        Write-Log "ERROR: Daemon failed to start"
        exit 1
    }
} catch {
    Write-Log "EXCEPTION: Failed to start daemon - $_"
    "$_" | Out-File "$env:USERPROFILE\.claude\claude-proxy-manager\daemon-crash.log" -Append
    exit 1
}
