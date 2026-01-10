# Setup Guide

Detailed installation and configuration guide for Claude Proxy Manager.

## Quick Install

```powershell
iwr -useb https://raw.githubusercontent.com/brandonkchow/claude-proxy-manager/main/scripts/install.ps1 | iex
```

The installer will guide you through the process. This guide provides additional details and manual setup options.

## Prerequisites

### Required
- **Windows 10/11** (Mac/Linux support planned)
- **PowerShell 5.1+** (pre-installed on Windows)
- **Node.js 18+** - [Download here](https://nodejs.org/)

### Recommended
- **At least one account:**
  - Google account for Antigravity (free), OR
  - Paid Claude Code subscription

## Installation Steps

### 1. Run the Installer

```powershell
# Download and run installer
iwr -useb https://raw.githubusercontent.com/brandonkchow/claude-proxy-manager/main/scripts/install.ps1 | iex
```

The installer will:
1. ✅ Check prerequisites (Node.js, PowerShell)
2. ✅ Install Claude Code CLI if missing
3. ✅ Install antigravity-claude-proxy if missing
4. ✅ Detect your accounts (Google + Claude Code)
5. ✅ Create priority configuration
6. ✅ Install scripts to `~/.claude/claude-proxy-manager/`
7. ✅ Add functions to your PowerShell profile
8. ✅ Optionally install remote access tools (SSH, psmux, HappyCoder)

### 2. Reload Your Profile

After installation completes:

```powershell
# Option 1: Reload profile
. $PROFILE

# Option 2: Restart PowerShell
# Close and reopen your PowerShell window
```

**Auto-Initialization (New!):**
When you reload your profile, it will automatically:
- Detect if priority.json is missing or incomplete
- Query the Antigravity proxy for available accounts
- Create/update priority configuration
- Display helpful status messages

You'll see:
```
[INFO] Antigravity accounts detected. Updating priority configuration...
Detecting available accounts...
  [OK] Found Antigravity account: your.email@gmail.com
  [OK] Claude Code authenticated
[OK] Priority configuration updated
```

This happens automatically - no manual setup required!

### 3. Verify Installation

```powershell
# Check if commands are available
claude-help

# Check current mode
claude-mode

# View account quotas
check-usage
```

You should see the help menu and current configuration!

## Configuration

### Account Priority

The installer creates a default priority order. You can customize it:

```powershell
# View current priority
get-priority

# Change priority order
set-priority
```

**Priority determines which account Claude uses first:**
- Accounts are tried in order until one with quota is found
- You can enable/disable specific accounts
- Two modes: `claude-first` (paid) or `antigravity-first` (free)

### Manual Priority Configuration

Edit `~/.claude/priority.json`:

```json
{
  "defaultPriority": "antigravity-first",
  "priority": [
    {
      "type": "antigravity",
      "email": "your.email@gmail.com",
      "enabled": true
    },
    {
      "type": "claude-code",
      "enabled": true
    }
  ]
}
```

### Claude Settings

The mode switcher manages `~/.claude/settings.json`:

**FREE mode (Antigravity):**
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8081",
    "ANTHROPIC_AUTH_TOKEN": "test"
  }
}
```

**PAID mode (Claude Code):**
```json
{
  "env": {}
}
```

## Optional Components

### Remote Access Setup

For mobile/SSH access, install these optional components:

#### OpenSSH Server
```powershell
# Run as Administrator
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

#### psmux (Windows tmux alternative)
```powershell
# Run as Administrator
choco install psmux
```

#### HappyCoder CLI
```powershell
npm install -g happy-coder
```

### Developer Mode (for symlinks)

Enable Developer Mode to allow `dual-sessions` to create symlinks without admin rights:

```powershell
# Run as Administrator (one-time setup):
.\enable-symlinks.ps1
```

**OR manually in Windows Settings:**
- Settings > Update & Security > For developers
- Turn on "Developer Mode"
- Restart or log out/in

**Why enable this?**
- `dual-sessions` creates symlinked directories
- Symlinks make FREE/PAID sessions appear distinct in HappyCoder app
- Without Developer Mode, you'll need admin rights each time

## Post-Installation

### First Time Setup

```powershell
# 1. Check your accounts and quotas
check-usage

# 2. Choose your default mode
claude-free   # Use free Google accounts
# OR
claude-paid   # Use paid Claude Code account

# 3. For mobile access, set up dual sessions
dual-sessions
```

### Test Your Setup

```powershell
# Test FREE mode
claude-free
claude "Hello, can you help me?"

# Test PAID mode
claude-paid
claude "Hello from paid mode!"

# Test mobile access
dual-sessions
# Scan QR codes with HappyCoder app
```

## File Locations

After installation, files are located at:

```
~/.claude/
├── settings.json              # Claude Code configuration (managed by switcher)
├── priority.json              # Account priority order
└── claude-proxy-manager/
    ├── scripts/
    │   ├── switch-claude-mode.ps1
    │   └── priority-functions.ps1
    └── profile-snippet.ps1    # PowerShell profile functions
```

Your PowerShell profile (`$PROFILE`) includes:
```powershell
# Claude Proxy Manager integration
. "$env:USERPROFILE\.claude\claude-proxy-manager\profile-snippet.ps1"
```

## Updating

To update to the latest version:

```powershell
# Re-run the installer
iwr -useb https://raw.githubusercontent.com/brandonkchow/claude-proxy-manager/main/scripts/install.ps1 | iex
```

The installer will:
- Skip already-installed components
- Update scripts to latest version
- Preserve your configuration files

## Uninstalling

### Remove PowerShell Integration

```powershell
# Edit your profile
notepad $PROFILE

# Remove or comment out these lines:
# . "$env:USERPROFILE\.claude\claude-proxy-manager\profile-snippet.ps1"
```

### Remove Installed Files

```powershell
# Remove manager files
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\claude-proxy-manager"

# Optionally remove config files
Remove-Item "$env:USERPROFILE\.claude\priority.json"

# Note: settings.json is used by Claude Code, keep it
```

### Uninstall Optional Components

```powershell
# Uninstall Claude Code CLI
npm uninstall -g @anthropic-ai/claude-code

# Uninstall Antigravity proxy
npm uninstall -g antigravity-claude-proxy

# Uninstall HappyCoder
npm uninstall -g happy-coder

# Uninstall psmux (requires admin)
choco uninstall psmux
```

## Troubleshooting Installation

### Node.js Not Found

**Error:** `node: command not found`

**Solution:**
1. Install Node.js from https://nodejs.org/
2. Restart PowerShell
3. Verify: `node --version`

### Permission Denied

**Error:** `execution of scripts is disabled on this system`

**Solution:**
```powershell
# Run as Administrator
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Proxy Won't Start

**Error:** `Port 8081 already in use`

**Solution:**
```powershell
# Find what's using port 8081
netstat -ano | findstr :8081

# Kill the process (replace PID with actual process ID)
taskkill /PID <pid> /F

# Or use a different port
$env:PORT = '8082'
start-proxy
```

### Claude CLI Not Found

**Error:** `claude: command not found`

**Solution:**
```powershell
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version
```

## Next Steps

- **[Usage Guide](USAGE.md)** - Learn daily workflows
- **[Quick Reference](QUICK_REFERENCE.md)** - Command cheat sheet
- **[Remote Access](REMOTE_ACCESS.md)** - Mobile and SSH setup
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues

Or just run `claude-help` to see available commands!
