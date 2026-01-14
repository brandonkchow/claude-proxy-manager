# Enable symlinks for dual-sessions (run as Administrator)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ENABLE SYMLINKS FOR DUAL-SESSIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run:" -ForegroundColor Yellow
    Write-Host "  .\enable-symlinks.ps1" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Checking Windows version..." -ForegroundColor Cyan
$version = [System.Environment]::OSVersion.Version

if ($version.Major -ge 10 -and $version.Build -ge 14972) {
    Write-Host "[OK] Windows 10/11 detected (Build $($version.Build))" -ForegroundColor Green
    Write-Host ""
    Write-Host "Enabling Developer Mode..." -ForegroundColor Cyan
    Write-Host "This allows symlink creation without admin rights" -ForegroundColor Gray
    Write-Host ""

    try {
        # Enable Developer Mode via registry
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord

        Write-Host "[SUCCESS] Developer Mode enabled!" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now run dual-sessions without admin rights" -ForegroundColor Green
        Write-Host "Symlinks will be created automatically" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to enable Developer Mode: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Alternative: Enable manually via Settings > Update & Security > For developers" -ForegroundColor Yellow
    }
} else {
    Write-Host "[INFO] Older Windows version detected" -ForegroundColor Yellow
    Write-Host "Symlinks will require running PowerShell as Administrator" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
