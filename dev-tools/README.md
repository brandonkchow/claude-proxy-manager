# Developer Tools

This directory contains developer utilities and manual testing scripts that are not part of the main codebase but are useful for development and testing.

## Directory Structure

```
dev-tools/
├── manual-tests/        # Manual testing scripts (not automated)
├── utilities/           # Utility scripts for developers
└── archived-docs/       # Archived documentation and notes
```

## Manual Tests (`manual-tests/`)

These scripts are for **manual testing** during development. They are not automated tests and are excluded from version control.

### Available Test Scripts

- **demo-help.ps1** - Demonstrates the help system
- **test-daemon-functions.ps1** - Manual daemon function testing
- **test-dual-sessions.ps1** - Interactive dual-sessions testing
- **test-dual-sessions-auto.ps1** - Automated dual-sessions test
- **test-help-update.ps1** - Test help system updates
- **test-auto-source.ps1** - Test auto-sourcing behavior
- **test-update-checker.ps1** - Test update checker with simulated versions
- **test-with-symlinks.ps1** - Test symlink creation
- **test-persistent-sessions.ps1** - Test persistent session behavior
- **test-claude-update.ps1** - Test claude-update command
- **run-dual-sessions-test.ps1** - Run dual-sessions test suite

### Usage

```powershell
# Run from the dev-tools/manual-tests directory
cd dev-tools/manual-tests

# Example: Test daemon functions
.\test-daemon-functions.ps1

# Example: Demo help system
.\demo-help.ps1
```

### Note

These scripts complement the automated Pester tests in `tests/` but allow for:
- Interactive testing
- Visual verification
- Edge case exploration
- Manual workflow validation

For **automated testing**, use the Pester test suite:
```powershell
# From repo root
.\Run-Tests.ps1
```

## Utilities (`utilities/`)

Developer utility scripts for common tasks.

### Available Utilities

- **dual-sessions-elevated.ps1** - Dual-sessions with automatic admin elevation for symlinks
- **enable-symlinks.ps1** - Enable symlink support (requires admin)

### Usage

```powershell
# Enable symlinks (run as admin)
.\dev-tools\utilities\enable-symlinks.ps1

# Run dual-sessions with auto-elevation
.\dev-tools\utilities\dual-sessions-elevated.ps1
```

## Archived Docs (`archived-docs/`)

Documentation that has been superseded or archived for reference.

### Available Docs

- **FIX_CHECK_USAGE.md** - Historical fix notes for check-usage display issue

## Contributing

When adding new developer tools:

1. Place manual test scripts in `manual-tests/`
2. Place utility scripts in `utilities/`
3. Update this README with a brief description
4. Ensure scripts are documented with comments

## See Also

- **[tests/](../tests/)** - Automated Pester test suite
- **[docs/TESTING.md](../docs/TESTING.md)** - Testing guide
- **[Run-Tests.ps1](../Run-Tests.ps1)** - Test runner for automated tests
