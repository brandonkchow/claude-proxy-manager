# Dual-sessions with automatic admin elevation for symlinks
# This creates symlinks with admin rights, then runs dual-sessions normally

param(
    [string]$WorkingDirectory = (Get-Location).Path,
    [string]$SessionName,
    [switch]$NoSymlinks
)

$baseName = if ($SessionName) { $SessionName } else { Split-Path -Leaf $WorkingDirectory }
$parentDir = Split-Path -Parent $WorkingDirectory
$freeDir = Join-Path $parentDir "$baseName-FREE"
$paidDir = Join-Path $parentDir "$baseName-PAID"

Write-Host "Dual-Sessions Setup (with symlink elevation)" -ForegroundColor Cyan
Write-Host ""

if (-not $NoSymlinks) {
    # Check if symlinks already exist
    $freeExists = Test-Path $freeDir
    $paidExists = Test-Path $paidDir

    if (-not $freeExists -or -not $paidExists) {
        Write-Host "Creating symlinks (requires admin)..." -ForegroundColor Yellow

        # Create elevated script to make symlinks
        $elevatedScript = @"
if (-not (Test-Path '$freeDir')) {
    New-Item -ItemType SymbolicLink -Path '$freeDir' -Target '$WorkingDirectory' | Out-Null
    Write-Host '[OK] FREE symlink created' -ForegroundColor Green
}
if (-not (Test-Path '$paidDir')) {
    New-Item -ItemType SymbolicLink -Path '$paidDir' -Target '$WorkingDirectory' | Out-Null
    Write-Host '[OK] PAID symlink created' -ForegroundColor Green
}
Write-Host ''
Write-Host 'Symlinks created successfully!' -ForegroundColor Green
Write-Host 'Press Enter to continue...'
Read-Host
"@

        $tempScript = "$env:TEMP\create-symlinks-temp.ps1"
        $elevatedScript | Set-Content $tempScript -Encoding UTF8

        # Run with elevation
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" -Verb RunAs -Wait

        Remove-Item $tempScript -ErrorAction SilentlyContinue
    } else {
        Write-Host "[OK] Symlinks already exist" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Starting dual-sessions..." -ForegroundColor Cyan

# Load profile and run dual-sessions
. "$env:USERPROFILE\.claude\claude-proxy-manager\profile-snippet.ps1"

$params = @{
    WorkingDirectory = $WorkingDirectory
}
if ($SessionName) { $params.SessionName = $SessionName }
if ($NoSymlinks) { $params.NoSymlinks = $true }

Start-DualSessions @params

Write-Host ""
Write-Host "Verification:" -ForegroundColor Cyan
if (Test-Path $freeDir) {
    Write-Host "  [SUCCESS] $baseName-FREE exists" -ForegroundColor Green
} else {
    Write-Host "  [INFO] No symlink (using same directory)" -ForegroundColor Yellow
}
if (Test-Path $paidDir) {
    Write-Host "  [SUCCESS] $baseName-PAID exists" -ForegroundColor Green
} else {
    Write-Host "  [INFO] No symlink (using same directory)" -ForegroundColor Yellow
}
