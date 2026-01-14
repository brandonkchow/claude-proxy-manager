# Testing Guide for Claude Proxy Manager

This document describes the testing infrastructure and how to run tests for Claude Proxy Manager.

## Table of Contents

- [Overview](#overview)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [CI/CD Pipeline](#cicd-pipeline)
- [Code Coverage](#code-coverage)

## Overview

Claude Proxy Manager uses **Pester 5.x** as its testing framework. The test suite includes:

- **Unit Tests**: Test individual functions and scripts in isolation
- **Integration Tests**: Test workflows and feature interactions
- **CI/CD**: Automated testing via GitHub Actions

## Test Structure

```
tests/
├── Unit/
│   ├── ModeSwitching.Tests.ps1      # Mode switching functionality
│   ├── PriorityFunctions.Tests.ps1  # Priority management
│   └── DaemonFunctions.Tests.ps1    # Daemon management
└── Integration/
    ├── DualSessions.Tests.ps1       # Dual-sessions workflow
    ├── HelpSystem.Tests.ps1         # Help system coverage
    └── UpdateChecker.Tests.ps1      # Update checker functionality
```

## Running Tests

### Prerequisites

Install Pester 5.x:

```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck -MinimumVersion 5.0.0
```

### Quick Start

Run all tests:

```powershell
.\Run-Tests.ps1
```

### Test Options

Run only unit tests:

```powershell
.\Run-Tests.ps1 -TestType Unit
```

Run only integration tests:

```powershell
.\Run-Tests.ps1 -TestType Integration
```

Run with code coverage:

```powershell
.\Run-Tests.ps1 -Coverage
```

Run in CI mode (exit with error code on failure):

```powershell
.\Run-Tests.ps1 -CI
```

Adjust verbosity:

```powershell
.\Run-Tests.ps1 -Verbosity Detailed  # None, Normal, Detailed, Diagnostic
```

### Direct Pester Invocation

You can also run Pester directly:

```powershell
# Run all tests
Invoke-Pester

# Run specific test file
Invoke-Pester -Path .\tests\Unit\ModeSwitching.Tests.ps1

# Run with configuration
$config = New-PesterConfiguration
$config.Run.Path = ".\tests\Unit"
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config
```

## Writing Tests

### Test File Naming Convention

- Unit tests: `<Component>.Tests.ps1`
- Integration tests: `<Feature>.Tests.ps1`

### Basic Test Structure

```powershell
BeforeAll {
    # Setup: Import modules, define paths
    $script:TestRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . "$script:TestRoot\scripts\my-script.ps1"
}

Describe "Feature Name" {
    Context "When scenario X happens" {
        BeforeEach {
            # Setup for each test
        }

        It "Should do Y" {
            # Arrange
            $input = "test"

            # Act
            $result = Invoke-Function -Input $input

            # Assert
            $result | Should -Be "expected"
        }

        AfterEach {
            # Cleanup after each test
        }
    }
}
```

### Mocking

Use Pester's mocking to isolate tests:

```powershell
Mock Invoke-WebRequest {
    return @{
        StatusCode = 200
        Content = '{"status": "ok"}'
    }
}

# Call function that uses Invoke-WebRequest
$result = Get-ProxyStatus

# Verify mock was called
Should -Invoke Invoke-WebRequest -Times 1
```

### Test Best Practices

1. **Isolate tests**: Use mocks to avoid external dependencies
2. **Test one thing**: Each test should verify a single behavior
3. **Use descriptive names**: "Should create backup before switching modes"
4. **Clean up**: Use `AfterEach` or `AfterAll` to clean up test artifacts
5. **Avoid hardcoded paths**: Use `$TestDrive` or `Join-Path` for paths
6. **Skip when appropriate**: Use `Set-ItResult -Skipped` for tests requiring admin/interactive input

## CI/CD Pipeline

GitHub Actions automatically runs tests on:

- **Push** to `main`, `develop`, or `feature/*` branches
- **Pull requests** to `main` or `develop`
- **Manual trigger** via workflow dispatch

### Pipeline Jobs

1. **Test**: Runs unit and integration tests
2. **Lint**: Runs PSScriptAnalyzer
3. **Validate JSON**: Checks JSON syntax
4. **Validate Docs**: Checks documentation files
5. **Integration Check**: Verifies script syntax

### Viewing Results

- Test results are uploaded as artifacts
- Test reports appear in the Actions tab
- Failed tests block PR merges

### Local CI Simulation

Run the same tests as CI locally:

```powershell
# Install dependencies
Install-Module -Name Pester -Force -SkipPublisherCheck -MinimumVersion 5.0.0
Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck

# Run tests
.\Run-Tests.ps1 -CI -Coverage

# Run linter
Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSGallery
```

## Code Coverage

Enable code coverage to see which lines are tested:

```powershell
.\Run-Tests.ps1 -Coverage
```

This generates `coverage-unit.xml` which can be viewed with:

- **VS Code**: Install "Coverage Gutters" extension
- **PowerShell**: Parse XML manually

### Coverage Goals

- **Critical functions**: 80%+ coverage (mode switching, priority, daemon)
- **Helper functions**: 60%+ coverage
- **Integration flows**: Key paths tested

## Test Categories

### Unit Tests

**ModeSwitching.Tests.ps1**:
- Switching to PAID mode clears proxy settings
- Switching to FREE mode sets proxy environment
- Settings preservation during switches
- Backup creation before modification

**PriorityFunctions.Tests.ps1**:
- Initialize priority config with defaults
- Get current priority configuration
- Set priority order (interactive tests skipped)
- JSON validation

**DaemonFunctions.Tests.ps1**:
- Get daemon status (running/stopped)
- Start daemon
- Stop daemon (preserves sessions)
- Restart daemon
- Configuration management

### Integration Tests

**DualSessions.Tests.ps1**:
- Symlink directory creation
- Daemon vs foreground sessions
- Proxy auto-start
- Window titles and configuration
- Custom working directories

**HelpSystem.Tests.ps1**:
- General help display
- Command-specific help
- Unknown command handling
- Help coverage for all public functions
- Formatting consistency

**UpdateChecker.Tests.ps1**:
- Check for updates
- Fetch and display release notes
- Update instructions
- Version comparison logic
- npm error handling

## Troubleshooting

### Pester Not Found

```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck -MinimumVersion 5.0.0
Import-Module Pester
```

### Tests Failing Locally but Passing in CI

- Check PowerShell version (CI uses Windows Server 2022)
- Verify module versions match CI
- Check for hardcoded paths or user-specific settings

### Admin-Required Tests Skipped

Some tests require admin rights (symlink creation). These are skipped automatically with:

```powershell
Set-ItResult -Skipped -Because "Requires admin rights"
```

### Mock Not Working

Ensure you're using Pester 5.x syntax:

```powershell
# Pester 5.x (correct)
Mock Get-Process { return @{ Name = "test" } }

# Pester 4.x (old, won't work)
Mock Get-Process -MockWith { return @{ Name = "test" } }
```

## Contributing

When adding new features:

1. **Write tests first** (TDD) or alongside implementation
2. **Update test documentation** if adding new test categories
3. **Ensure CI passes** before creating PR
4. **Aim for 70%+ coverage** for new code

## Resources

- [Pester Documentation](https://pester.dev/docs/quick-start)
- [Pester Assertions](https://pester.dev/docs/assertions/should)
- [Pester Mocking](https://pester.dev/docs/usage/mocking)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
