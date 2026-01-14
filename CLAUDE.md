# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Proxy Manager is a Windows PowerShell-based tool that enables seamless switching between Claude Code paid accounts and Antigravity proxy (free Google accounts). It manages account priorities, handles proxy configuration, and integrates with remote access workflows.

**Key Capabilities:**
- Switch between paid Claude Code API and free Antigravity proxy accounts
- Manage multiple Google accounts via Antigravity proxy with priority ordering
- Auto-detect and configure available accounts
- Integrate with SSH, psmux (Windows tmux), and HappyCoder for remote/mobile workflows
- Handle Claude settings.json configuration for different modes
- **Persistent HappyCoder sessions** via happy daemon (survive restarts and reboots)

## Development Workflow

### When Adding New Features

**ALWAYS update these after implementation:**

1. **Help System** (`config/profile-snippet.ps1`):
   - Add command-specific help in `Show-ClaudeHelp` function
   - Add to general help categories
   - Add aliases to alias section
   - Test: `claude-help <new-command>`

2. **Documentation** (update ALL relevant files):
   - `docs/QUICK_REFERENCE.md` - Add to command reference table
   - `docs/USAGE.md` - Add usage examples and workflows
   - `docs/TROUBLESHOOTING.md` - Add common issues and solutions
   - `docs/REMOTE_ACCESS.md` - If feature affects remote/mobile workflows
   - `README.md` - Add to features list if user-facing
   - `CLAUDE.md` - Update architecture notes and testing checklist

3. **Testing**:
   - Add Pester test cases to `tests/Unit/` or `tests/Integration/`
   - Run tests: `.\Run-Tests.ps1`
   - Ensure CI passes: All tests must pass in GitHub Actions
   - Add test cases to Testing Checklist section below
   - Document edge cases in TROUBLESHOOTING.md
   - See `docs/TESTING.md` for comprehensive testing guide

4. **Examples**:
   - Create example usage in `docs/USAGE.md`
   - Add to quick start section if critical workflow

**Example Workflow:**
```
1. Implement feature in profile-snippet.ps1
2. Write Pester tests in tests/Unit/ or tests/Integration/
3. Run tests: .\Run-Tests.ps1
4. Add Show-ClaudeHelp case for new command
5. Update QUICK_REFERENCE.md command table
6. Add usage examples to USAGE.md
7. Add troubleshooting section to TROUBLESHOOTING.md
8. Update README.md features list
9. Test: claude-help <command>
10. Test: Actual command execution
11. Ensure CI/CD passes (GitHub Actions)
12. Commit with message: "feat: <feature> + tests + docs"
```

## Critical Architecture Concepts

### Mode Switching System

The core functionality revolves around manipulating `~/.claude/settings.json`:

**PAID Mode** (Claude Code account):
- Clears `ANTHROPIC_BASE_URL` environment variable
- Uses default Anthropic API directly
- User authenticates via `claude /login`

**FREE Mode** (Antigravity proxy):
- Sets `ANTHROPIC_BASE_URL=http://localhost:8081`
- Sets `ANTHROPIC_AUTH_TOKEN=test` (dummy token)
- Routes requests through local Antigravity proxy
- Proxy manages multiple Google accounts and handles fallback to Gemini

### Priority System

Priority configuration stored in `~/.claude/priority.json`:
- Defines order of account preference (Antigravity accounts or Claude Code)
- Each account can be enabled/disabled
- Supports `claude-first` or `antigravity-first` default modes
- Auto-detected during installation by querying proxy API and Claude CLI

### Installation Architecture

The installer (`scripts/install.ps1`) follows this flow:
1. Check prerequisites (Node.js, npm)
2. Install Claude Code CLI if missing
3. Install antigravity-claude-proxy if missing
4. Detect accounts by querying proxy API endpoint `/account-limits?format=json`
5. Create priority configuration
6. Install files to `~/.claude/claude-proxy-manager/scripts/`
7. Inject profile snippet into PowerShell `$PROFILE`
8. Optionally install remote access tools (OpenSSH, psmux, HappyCoder)

### PowerShell Profile Integration

The system adds functions to user's PowerShell profile that:
- Auto-load on shell startup
- Provide convenient aliases (`claude-paid`, `claude-free`, `check-usage`, etc.)
- Display current mode on profile load
- Manage proxy lifecycle

## Common Development Commands

### Testing Mode Switching

```powershell
# Switch to paid mode
.\scripts\switch-claude-mode.ps1 paid

# Switch to free mode
.\scripts\switch-claude-mode.ps1 free

# Verify settings were updated
cat ~/.claude/settings.json
```

### Testing Installation

```powershell
# Run full installer in non-interactive mode
.\scripts\install.ps1 -NonInteractive

# Skip prerequisite checks
.\scripts\install.ps1 -SkipPrereqs

# Test installer with specific priority
# (Modify script temporarily to test)
```

### Testing Priority Functions

```powershell
# Source the functions
. .\scripts\priority-functions.ps1

# Initialize priority config
Initialize-ClaudePriority -DefaultPriority 'claude-first'

# View priority order
Get-ClaudePriority

# Test priority setting UI
Set-ClaudePriority
```

### Checking Proxy Integration

```powershell
# Check if proxy is running
Test-NetConnection -ComputerName localhost -Port 8081

# Query account limits
Invoke-RestMethod -Uri "http://localhost:8081/account-limits?format=json"

# Check proxy health endpoint
Invoke-WebRequest -Uri "http://localhost:8081/health" -UseBasicParsing
```

## File Structure

```
claude-proxy-manager/
├── scripts/
│   ├── install.ps1              # Main installer with UAC elevation
│   ├── switch-claude-mode.ps1   # Mode switching logic
│   ├── priority-functions.ps1   # Priority management functions
│   └── daemon-startup.ps1       # Daemon auto-start script
├── config/
│   ├── settings.example.json    # Example Claude settings (FREE mode)
│   ├── priority.example.json    # Example priority configuration
│   ├── daemon-config.json       # Daemon configuration
│   └── profile-snippet.ps1      # PowerShell profile functions
├── tests/
│   ├── Unit/                    # Unit tests (Pester)
│   │   ├── ModeSwitching.Tests.ps1
│   │   ├── PriorityFunctions.Tests.ps1
│   │   └── DaemonFunctions.Tests.ps1
│   └── Integration/             # Integration tests (Pester)
│       ├── DualSessions.Tests.ps1
│       ├── HelpSystem.Tests.ps1
│       └── UpdateChecker.Tests.ps1
├── .github/
│   └── workflows/
│       └── ci.yml               # GitHub Actions CI/CD
├── docs/
│   ├── QUICK_REFERENCE.md       # Command cheat sheet
│   ├── USAGE.md                 # Usage guide
│   ├── TROUBLESHOOTING.md       # Common issues
│   ├── REMOTE_ACCESS.md         # SSH, psmux, HappyCoder setup
│   ├── ARCHITECTURE.md          # Technical architecture
│   ├── SETUP.md                 # Installation guide
│   └── TESTING.md               # Testing guide (NEW)
└── Run-Tests.ps1                # Test runner script (NEW)
```

**User Files** (created during installation, in .gitignore):
- `~/.claude/settings.json` - Claude Code configuration (managed by switching)
- `~/.claude/priority.json` - Account priority order
- `~/.claude/claude-proxy-manager/` - Installed scripts

## Important Implementation Notes

### Thinking Model Incompatibility

**CRITICAL**: Antigravity proxy cannot process "thinking blocks" from Claude's extended thinking models (models with `-thinking` suffix). Switching between paid and free modes mid-conversation will cause API 400 errors.

When implementing features:
- Never auto-switch modes during active conversations
- Warn users about thinking model incompatibility
- Require fresh conversation when mode changes

### UAC Elevation Pattern

The installer uses a specific pattern for operations requiring admin privileges:

```powershell
# Create script content
$elevatedScript = @"
# Commands requiring admin
"@

# Write to temp file
$tempScript = "$env:TEMP\temp-script.ps1"
$elevatedScript | Set-Content $tempScript

# Execute with elevation
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" -Verb RunAs -Wait

# Cleanup
Remove-Item $tempScript -ErrorAction SilentlyContinue
```

This pattern is used for:
- OpenSSH Server installation
- Chocolatey installation
- psmux installation

### PowerShell Profile Snippet Pattern

When adding to `$PROFILE`:

```powershell
# Check if already configured to avoid duplicates
$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notmatch "unique-marker-text") {
    Add-Content -Path $profilePath -Value $snippet
}
```

### Proxy Health Checks

Always check proxy status before operations:

```powershell
try {
    $proxyRunning = Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($proxyRunning) {
        # Proxy is running
    }
} catch {
    # Proxy not available
}
```

## Remote Access Integration

### psmux vs tmux

- Windows doesn't support tmux natively
- `psmux` is a Windows-native tmux alternative
- Installed via Chocolatey
- Provides `tmux` alias for familiarity
- Essential for persistent remote sessions

### HappyCoder Integration

HappyCoder enables mobile Claude Code usage:

**With Antigravity Proxy:**
```powershell
happy --claude-env ANTHROPIC_AUTH_TOKEN=test --claude-env ANTHROPIC_BASE_URL=http://localhost:8081
```

**With Paid Claude Code:**
```powershell
happy
```

The installer creates convenient aliases (`happy-free`, `happy-paid`, `dual-sessions`).

### Dual-Session Setup

The installer creates helper scripts for running both FREE and PAID sessions simultaneously in psmux, allowing mobile users to switch between them via QR code scanning.

### Persistent HappyCoder Sessions (happy daemon)

**NEW**: HappyCoder sessions can persist across terminal restarts and computer reboots using `happy daemon`:

**Key Commands:**
```powershell
daemon-start     # Start happy daemon (keeps sessions alive)
daemon-stop      # Stop daemon (sessions persist on relay server)
daemon-status    # Check daemon health
daemon-restart   # Restart daemon (safe - sessions survive)
```

**Architecture:**
- `happy daemon` runs as background service (detached from terminal)
- Sessions stored on happy-server relay (cloud-based at happy.engineering)
- Daemon is connection manager between local CLI and relay
- Sessions survive daemon restarts because they're on the relay server
- Auto-starts on Windows login via Task Scheduler

**Integration with dual-sessions:**
```powershell
dual-sessions -UseDaemon    # Persistent sessions (survive restarts)
dual-sessions               # Standard (foreground, non-persistent)
```

**Implementation Files:**
- `scripts/daemon-startup.ps1` - Auto-start script for Windows login
- `config/daemon-config.json` - Daemon configuration
- `config/profile-snippet.ps1` - Daemon management functions
- Task Scheduler task: "HappyCoderDaemon"

**Important Notes:**
- Sessions survive daemon restarts ✅
- Sessions survive computer reboots (if auto-start enabled) ✅
- `happy daemon stop` explicitly keeps sessions alive on relay
- `happy doctor clean` WILL kill all sessions (nuclear option) ❌
- Safe to restart daemon after `npm update -g happy-coder`

**Dependencies:**
- Requires `happy-coder` npm package (v0.13.0+)
- Antigravity proxy must start before daemon (for FREE mode)
- daemon-startup.ps1 handles dependency ordering

## Testing

### Automated Testing (Pester)

The project uses **Pester 5.x** for automated testing. See `docs/TESTING.md` for comprehensive guide.

**Quick Start:**
```powershell
# Run all tests
.\Run-Tests.ps1

# Run with code coverage
.\Run-Tests.ps1 -Coverage

# Run specific test suite
.\Run-Tests.ps1 -TestType Unit
.\Run-Tests.ps1 -TestType Integration
```

**Test Structure:**
- `tests/Unit/` - Unit tests for individual functions
- `tests/Integration/` - Integration tests for workflows
- GitHub Actions runs all tests on push/PR

**Coverage:**
- **Unit Tests**: ModeSwitching, PriorityFunctions, DaemonFunctions
- **Integration Tests**: DualSessions, HelpSystem, UpdateChecker

### Manual Testing Checklist

When modifying core functionality:

1. **Mode Switching**:
   - ✅ Test mode switching preserves existing settings backup
   - ✅ Verify environment variables cleared/set correctly
   - ✅ Check settings.json structure after switch

2. **Priority Management**:
   - ✅ Verify priority.json format after Initialize-ClaudePriority
   - ✅ Test priority ordering and enable/disable

3. **Installation**:
   - ✅ Check profile snippet doesn't duplicate on reinstall
   - ✅ Verify UAC elevation scripts clean up temp files
   - ✅ Test non-interactive mode for CI/CD scenarios

4. **Proxy Integration**:
   - ✅ Ensure proxy health checks handle timeout gracefully
   - ✅ Test with and without proxy running
   - ✅ Test with and without Claude Code authentication

5. **Daemon Management**:
   - ✅ **Test daemon persistence**: Start daemon, close terminals, verify sessions reconnect
   - ✅ **Test daemon auto-start**: Reboot PC, verify daemon running after login
   - ✅ **Test daemon restart**: Restart daemon, verify sessions survive

6. **CI/CD**:
   - ✅ All Pester tests pass
   - ✅ PSScriptAnalyzer passes
   - ✅ JSON validation passes
   - ✅ Documentation links valid

### Running Tests Before Commit

**ALWAYS run tests before committing:**
```powershell
# Quick test run
.\Run-Tests.ps1

# Full CI simulation
.\Run-Tests.ps1 -CI -Coverage
Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSGallery
```

## Common Pitfalls

1. **Forgetting to reload profile**: After installation, users must run `. $PROFILE` or restart terminal
2. **Proxy not running**: Many features require proxy at localhost:8081
3. **JSON encoding**: Always use `-Encoding utf8` when writing JSON files
4. **Error suppression**: Use `-ErrorAction SilentlyContinue` for checks, but preserve errors for critical operations
5. **Path quoting**: Use quotes around paths in PowerShell arguments: `-File "$tempScript"`
6. **Daemon not auto-starting**: Check Task Scheduler task exists and is enabled
7. **Sessions lost after daemon restart**: This shouldn't happen - if it does, check relay server connection
8. **Port conflicts**: Ensure no other process using daemon's port (check with `happy doctor`)

