# Test Runner Script for Claude Proxy Manager
# Runs all Pester tests with proper configuration and reporting

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('All', 'Unit', 'Integration')]
    [string]$TestType = 'All',

    [Parameter()]
    [switch]$Coverage,

    [Parameter()]
    [switch]$CI,

    [Parameter()]
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string]$Verbosity = 'Detailed'
)

# Ensure Pester is installed
if (-not (Get-Module -Name Pester -ListAvailable | Where-Object { $_.Version -ge '5.0.0' })) {
    Write-Host "Installing Pester 5.x..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck -MinimumVersion 5.0.0
}

Import-Module Pester -MinimumVersion 5.0.0

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Proxy Manager Test Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testResults = @()

function Invoke-TestSuite {
    param(
        [string]$Name,
        [string]$Path
    )

    Write-Host "Running $Name tests..." -ForegroundColor Yellow
    Write-Host ""

    $config = New-PesterConfiguration

    # Configure test paths
    $config.Run.Path = $Path
    $config.Output.Verbosity = $Verbosity

    # Test results
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = "test-results-$($Name.ToLower()).xml"
    $config.TestResult.OutputFormat = 'NUnitXml'

    # Code coverage (only for unit tests)
    if ($Coverage -and $Name -eq 'Unit') {
        $config.CodeCoverage.Enabled = $true
        $config.CodeCoverage.Path = @(
            ".\scripts\*.ps1",
            ".\config\*.ps1"
        )
        $config.CodeCoverage.OutputPath = "coverage-$($Name.ToLower()).xml"
        $config.CodeCoverage.OutputFormat = 'CoverageGutters'
    }

    # CI mode settings
    if ($CI) {
        $config.Run.Exit = $false
        $config.Should.ErrorAction = 'Stop'
    }

    $result = Invoke-Pester -Configuration $config

    Write-Host ""
    Write-Host "Results for $Name tests:" -ForegroundColor Cyan
    Write-Host "  Passed:  $($result.PassedCount)" -ForegroundColor Green
    Write-Host "  Failed:  $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -gt 0) { "Red" } else { "Gray" })
    Write-Host "  Skipped: $($result.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Total:   $($result.TotalCount)" -ForegroundColor White
    Write-Host ""

    return $result
}

# Run tests based on TestType parameter
switch ($TestType) {
    'Unit' {
        $unitResult = Invoke-TestSuite -Name 'Unit' -Path '.\tests\Unit'
        $testResults += $unitResult
    }
    'Integration' {
        $integrationResult = Invoke-TestSuite -Name 'Integration' -Path '.\tests\Integration'
        $testResults += $integrationResult
    }
    'All' {
        $unitResult = Invoke-TestSuite -Name 'Unit' -Path '.\tests\Unit'
        $testResults += $unitResult

        $integrationResult = Invoke-TestSuite -Name 'Integration' -Path '.\tests\Integration'
        $testResults += $integrationResult
    }
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalPassed = ($testResults | Measure-Object -Property PassedCount -Sum).Sum
$totalFailed = ($testResults | Measure-Object -Property FailedCount -Sum).Sum
$totalSkipped = ($testResults | Measure-Object -Property SkippedCount -Sum).Sum
$totalTests = ($testResults | Measure-Object -Property TotalCount -Sum).Sum

Write-Host "Total Passed:  $totalPassed" -ForegroundColor Green
Write-Host "Total Failed:  $totalFailed" -ForegroundColor $(if ($totalFailed -gt 0) { "Red" } else { "Gray" })
Write-Host "Total Skipped: $totalSkipped" -ForegroundColor Yellow
Write-Host "Total Tests:   $totalTests" -ForegroundColor White
Write-Host ""

if ($Coverage -and (Test-Path "coverage-unit.xml")) {
    Write-Host "Code coverage report generated: coverage-unit.xml" -ForegroundColor Cyan
    Write-Host ""
}

# Exit with appropriate code for CI
if ($totalFailed -gt 0) {
    Write-Host "❌ Tests FAILED" -ForegroundColor Red
    if ($CI) {
        exit 1
    }
} else {
    Write-Host "✅ All tests PASSED" -ForegroundColor Green
    if ($CI) {
        exit 0
    }
}

Write-Host ""
