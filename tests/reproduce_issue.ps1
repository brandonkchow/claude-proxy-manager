
# Set up environment
$originalUserProfile = $env:USERPROFILE
$tempDir = Join-Path $PWD "temp_home"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$env:USERPROFILE = $tempDir

# Create config directory structure
$configDir = "$env:USERPROFILE\.claude\claude-proxy-manager"
New-Item -ItemType Directory -Path $configDir -Force | Out-Null

# Create daemon-config.json to enable auto-start
@{
    autoStartDaemon = $true
    autoStartMode = "none"
} | ConvertTo-Json | Set-Content "$configDir\daemon-config.json"

# Mock 'happy' command
function happy {
    param(
        [string]$Command,
        [string]$SubCommand
    )
    Start-Sleep -Milliseconds 200
    return "Daemon is running`n2 active sessions`n3 happy processes"
}

# Create a mock Get-Command that returns true for 'happy'
# In PowerShell, we can't easily mock Get-Command for a specific command without affecting others
# But in the script `Get-Command happy -ErrorAction SilentlyContinue` is used.
# If I define a function `happy`, Get-Command happy should find it.

Write-Host "Starting measurement..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Source the profile snippet
. "$PWD/config/profile-snippet.ps1"

$sw.Stop()
Write-Host "Profile load time: $($sw.ElapsedMilliseconds) ms"

# Cleanup
$env:USERPROFILE = $originalUserProfile
Remove-Item $tempDir -Recurse -Force
