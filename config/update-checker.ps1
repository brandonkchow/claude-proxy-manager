# Update Checker for Antigravity Claude Proxy
# Checks for updates on profile load

function Check-AntigravityUpdate {
    param(
        [switch]$Force  # Force check even if recently checked
    )

    try {
        # Prevent native commands (like npm) from triggering terminating errors on stderr output
        $ErrorActionPreference = 'Continue'

        # Check if we've checked recently (cache for 24 hours)
        $cacheFile = "$env:USERPROFILE\.claude\.update-check-cache"
        $now = Get-Date

        if (-not $Force -and (Test-Path $cacheFile)) {
            $lastCheck = Get-Content $cacheFile -Raw | ConvertFrom-Json
            $lastCheckTime = [DateTime]::Parse($lastCheck.timestamp)

            if (($now - $lastCheckTime).TotalHours -lt 24) {
                # Checked recently, skip
                return
            }
        }

        # Get installed version
        # Optimization: Try direct execution first (milliseconds) vs npm list (seconds)
        $installedVersion = $null

        try {
            $versionOutput = antigravity-claude-proxy --version 2>&1
            if ($LASTEXITCODE -eq 0 -and $versionOutput -match '(\d+\.\d+\.\d+)') {
                $installedVersion = $matches[1]
            }
        } catch {
            # Command not found or execution failed
        }

        # Fallback to npm list (slower) if direct check failed
        if (-not $installedVersion) {
            $installedOutput = npm list -g antigravity-claude-proxy --depth=0 2>&1 | Select-String "antigravity-claude-proxy@"
            if (-not $installedOutput) {
                # Not installed, skip
                return
            }
            $installedVersion = ($installedOutput -split '@')[1].Trim()
        }

        # Get latest version from npm
        $latestVersion = npm view antigravity-claude-proxy version 2>&1

        if (-not $latestVersion) {
            # Can't fetch latest version, skip
            return
        }

        # Save cache
        @{
            timestamp = $now.ToString('o')
            installed = $installedVersion
            latest = $latestVersion
        } | ConvertTo-Json | Set-Content $cacheFile -Encoding UTF8

        # Compare versions
        if ($installedVersion -ne $latestVersion) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host "  UPDATE AVAILABLE" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "antigravity-claude-proxy update available:" -ForegroundColor Cyan
            Write-Host "  Current: v$installedVersion" -ForegroundColor Gray
            Write-Host "  Latest:  v$latestVersion" -ForegroundColor Green
            Write-Host ""

            # Fetch release notes from GitHub
            try {
                $releaseUrl = "https://api.github.com/repos/badrisnarayanan/antigravity-claude-proxy/releases/latest"
                $release = Invoke-RestMethod -Uri $releaseUrl -Headers @{"User-Agent"="PowerShell"} -TimeoutSec 5 -ErrorAction Stop

                if ($release.body) {
                    Write-Host "What's New:" -ForegroundColor Cyan
                    $releaseNotes = $release.body -split "`n" | Select-Object -First 10
                    $releaseNotes | ForEach-Object {
                        Write-Host "  $_" -ForegroundColor Gray
                    }
                    Write-Host ""
                }
            } catch {
                # GitHub fetch failed, skip release notes
            }

            Write-Host "To update, run:" -ForegroundColor Yellow
            Write-Host "  npm install -g antigravity-claude-proxy@latest" -ForegroundColor White
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host ""

            # Prompt user
            $response = Read-Host "Update now? (y/N)"
            if ($response -eq 'y' -or $response -eq 'Y') {
                Write-Host ""
                Write-Host "Updating antigravity-claude-proxy..." -ForegroundColor Cyan
                npm install -g antigravity-claude-proxy@latest

                Write-Host ""
                Write-Host "[OK] Update complete!" -ForegroundColor Green
                Write-Host "Restart any running proxy instances for changes to take effect." -ForegroundColor Yellow
                Write-Host ""
            } else {
                Write-Host ""
                Write-Host "Skipped update. Run 'check-proxy-update' anytime to check again." -ForegroundColor Gray
                Write-Host ""
            }
        }
    } catch {
        # Silent fail - don't disrupt profile load
    }
}

# Alias for manual checking
Set-Alias -Name check-proxy-update -Value Check-AntigravityUpdate
