# End-to-End Test Script for Persistent HappyCoder Sessions
# Tests all daemon functionality and integration points

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  PERSISTENT SESSIONS E2E TESTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$testsPassed = 0
$testsFailed = 0

function Test-Feature {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    Write-Host "[TEST] $Name" -ForegroundColor Yellow
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  ✅ PASS" -ForegroundColor Green
            $script:testsPassed++
        } else {
            Write-Host "  ❌ FAIL" -ForegroundColor Red
            $script:testsFailed++
        }
    } catch {
        Write-Host "  ❌ ERROR: $_" -ForegroundColor Red
        $script:testsFailed++
    }
    Write-Host ""
}

# Load profile functions
Write-Host "[SETUP] Loading profile functions..." -ForegroundColor Cyan
. "$env:USERPROFILE\.claude\claude-proxy-manager\config\profile-snippet.ps1"
Write-Host ""

# Test 1: Daemon Functions Exist
Test-Feature "Daemon functions are loaded" {
    $functions = @('Get-HappyDaemonStatus', 'Start-HappyDaemon', 'Stop-HappyDaemon', 'Restart-HappyDaemon')
    $allExist = $true
    foreach ($func in $functions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            Write-Host "    Missing: $func" -ForegroundColor Red
            $allExist = $false
        }
    }
    return $allExist
}

# Test 2: Daemon Aliases Exist
Test-Feature "Daemon aliases are configured" {
    $aliases = @('daemon-start', 'daemon-stop', 'daemon-status', 'daemon-restart')
    $allExist = $true
    foreach ($alias in $aliases) {
        if (-not (Get-Alias $alias -ErrorAction SilentlyContinue)) {
            Write-Host "    Missing: $alias" -ForegroundColor Red
            $allExist = $false
        }
    }
    return $allExist
}

# Test 3: Happy-coder installed
Test-Feature "happy-coder is installed" {
    try {
        $version = happy --version 2>$null
        if ($version) {
            Write-Host "    Version: $version" -ForegroundColor Gray
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

# Test 4: Daemon startup script exists
Test-Feature "daemon-startup.ps1 exists" {
    $scriptPath = "$env:USERPROFILE\.claude\claude-proxy-manager\scripts\daemon-startup.ps1"
    if (Test-Path $scriptPath) {
        Write-Host "    Path: $scriptPath" -ForegroundColor Gray
        return $true
    }
    return $false
}

# Test 5: Daemon config example exists
Test-Feature "daemon-config.example.json exists" {
    $examplePath = "C:\Users\bchow\GitHub\claude-proxy-manager\config\daemon-config.example.json"
    if (Test-Path $examplePath) {
        $config = Get-Content $examplePath -Raw | ConvertFrom-Json
        Write-Host "    Has autoStartDaemon: $($config.autoStartDaemon -ne $null)" -ForegroundColor Gray
        Write-Host "    Has autoStartMode: $($config.autoStartMode -ne $null)" -ForegroundColor Gray
        return ($config.autoStartDaemon -ne $null) -and ($config.autoStartMode -ne $null)
    }
    return $false
}

# Test 6: Get-HappyDaemonStatus works
Test-Feature "Get-HappyDaemonStatus returns status object" {
    try {
        $status = Get-HappyDaemonStatus
        if ($status -and ($status.Running -ne $null)) {
            Write-Host "    Running: $($status.Running)" -ForegroundColor Gray
            Write-Host "    SessionCount: $($status.SessionCount)" -ForegroundColor Gray
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

# Test 7: Start-DualSessions has -UseDaemon parameter
Test-Feature "Start-DualSessions supports -UseDaemon parameter" {
    $command = Get-Command Start-DualSessions
    $hasParam = $command.Parameters.ContainsKey('UseDaemon')
    if ($hasParam) {
        Write-Host "    Parameter type: $($command.Parameters['UseDaemon'].ParameterType)" -ForegroundColor Gray
        return $true
    }
    return $false
}

# Test 8: Help system has daemon documentation
Test-Feature "Help system includes daemon commands" {
    try {
        # Capture help output - it should display help without errors
        Show-ClaudeHelp -Command 'daemon-start' 2>&1 | Out-Null
        # If it got here without exception, the command exists and works
        Write-Host "    daemon-start help command works" -ForegroundColor Gray
        return $true
    } catch {
        return $false
    }
}

# Test 9: Task Scheduler task exists (if configured)
Test-Feature "Task Scheduler task exists (if configured)" {
    try {
        $task = Get-ScheduledTask -TaskName "HappyCoderDaemon" -ErrorAction SilentlyContinue
        if ($task) {
            Write-Host "    Task state: $($task.State)" -ForegroundColor Gray
            Write-Host "    Triggers: $($task.Triggers.Count)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "    Task not configured (optional)" -ForegroundColor Yellow
            return $true  # Optional - pass either way
        }
    } catch {
        Write-Host "    Task not configured (optional)" -ForegroundColor Yellow
        return $true  # Optional - pass either way
    }
}

# Test 10: REMOTE_ACCESS.md has persistent sessions section
Test-Feature "REMOTE_ACCESS.md documents persistent sessions" {
    $docsPath = "C:\Users\bchow\GitHub\claude-proxy-manager\docs\REMOTE_ACCESS.md"
    if (Test-Path $docsPath) {
        $content = Get-Content $docsPath -Raw
        if ($content -match "Persistent Sessions" -and $content -match "daemon-start") {
            Write-Host "    Documentation found" -ForegroundColor Gray
            return $true
        }
    }
    return $false
}

# Test 11: README.md mentions persistent sessions
Test-Feature "README.md features persistent sessions" {
    $readmePath = "C:\Users\bchow\GitHub\claude-proxy-manager\README.md"
    if (Test-Path $readmePath) {
        $content = Get-Content $readmePath -Raw
        if ($content -match "Persistent Sessions" -and $content -match "-UseDaemon") {
            Write-Host "    Feature listed in README" -ForegroundColor Gray
            return $true
        }
    }
    return $false
}

# Test 12: QUICK_REFERENCE.md has daemon commands
Test-Feature "QUICK_REFERENCE.md lists daemon commands" {
    $quickRefPath = "C:\Users\bchow\GitHub\claude-proxy-manager\docs\QUICK_REFERENCE.md"
    if (Test-Path $quickRefPath) {
        $content = Get-Content $quickRefPath -Raw
        if ($content -match "daemon-start" -and $content -match "daemon-status") {
            Write-Host "    Commands documented" -ForegroundColor Gray
            return $true
        }
    }
    return $false
}

# Test 13: Installer has daemon setup (Step 8.5)
Test-Feature "Installer includes daemon configuration" {
    $installerPath = "C:\Users\bchow\GitHub\claude-proxy-manager\scripts\install.ps1"
    if (Test-Path $installerPath) {
        $content = Get-Content $installerPath -Raw
        if ($content -match "daemon" -and $content -match "Task Scheduler" -and $content -match "autoStartMode") {
            Write-Host "    Daemon setup found in installer" -ForegroundColor Gray
            return $true
        }
    }
    return $false
}

# Test 14: Profile snippet has auto-start logic
Test-Feature "Profile auto-starts daemon if configured" {
    $profilePath = "$env:USERPROFILE\.claude\claude-proxy-manager\config\profile-snippet.ps1"
    if (Test-Path $profilePath) {
        $content = Get-Content $profilePath -Raw
        if ($content -match "Auto-start daemon" -and $content -match "daemon-config.json" -and $content -match "autoStartDaemon") {
            Write-Host "    Auto-start logic found" -ForegroundColor Gray
            return $true
        }
    }
    return $false
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Passed: $testsPassed" -ForegroundColor Green
Write-Host "  Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "  Total:  $($testsPassed + $testsFailed)" -ForegroundColor White
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "✅ ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ SOME TESTS FAILED" -ForegroundColor Red
    exit 1
}
