# Usage Guide

Daily workflows and common tasks with Claude Proxy Manager.

## Quick Start

### Get Help Anytime

```powershell
# Show all commands
claude-help

# Detailed help for specific command
claude-help dual-sessions
claude-help claude-free
claude-help check-usage
```

### Check Your Status

```powershell
# View current mode and configuration
claude-mode

# Check all account quotas
check-usage

# View priority order
get-priority
```

## Common Workflows

### Switching Between Modes

#### Switch to FREE Mode (Antigravity)

```powershell
# Switch to free Google accounts
claude-free

# The proxy will start automatically if needed
# Your settings are updated to use localhost:8081
```

**When to use FREE:**
- Casual browsing and experimentation
- Non-critical tasks
- When paid quota is low
- Learning and practice

#### Switch to PAID Mode (Claude Code)

```powershell
# Switch to your paid Claude Code account
claude-paid

# Settings revert to use Anthropic API directly
```

**When to use PAID:**
- Important work projects
- Production code
- When you need the latest models
- When FREE quota is exhausted

### Monitoring Usage

```powershell
# See detailed quota information
check-usage
```

**Example output:**
```
========================================
   CLAUDE USAGE OVERVIEW
========================================

Account Priority Order:
[1] FREE Antigravity - your.email@gmail.com
    Claude (Sonnet 4.5): 85% (Resets: 1/10/2026 11:30 PM)
    Gemini (Flash 3):    92% (Resets: 1/10/2026 11:30 PM)

[2] PAID Claude Code Account
    Status: Available (Switch with: claude-paid)
    Note: Check usage at https://console.anthropic.com/settings/limits

Fallback: Claude -> Gemini (automatic)

Change priority: set-priority
========================================
```

## Mobile Access with HappyCoder

### Quick Setup (Recommended)

```powershell
# Start both FREE and PAID sessions
dual-sessions
```

**What happens:**
1. Two PowerShell windows open (GREEN and BLUE)
2. Each displays a QR code
3. Symlinked directories created (`YourProject-FREE` and `YourProject-PAID`)
4. Sessions appear distinct in HappyCoder app

**Scan the QR codes:**
- GREEN window → FREE mode session
- BLUE window → PAID mode session
- Switch between them in your HappyCoder app!

### Custom Session Names

```powershell
# Use custom session names
dual-sessions -SessionName "WebDev"

# Creates: WebDev-FREE and WebDev-PAID
```

### Individual Sessions

```powershell
# Start just FREE mode for mobile
happy-free

# Start just PAID mode for mobile
happy-paid
```

## Priority Management

### View Priority Order

```powershell
# See which accounts will be tried first
get-priority
```

### Change Priority

```powershell
# Interactive priority configuration
set-priority
```

**You can:**
- Reorder accounts
- Enable/disable specific accounts
- Choose between `claude-first` or `antigravity-first` defaults

### Initialize Priority (First Time)

```powershell
# Set up priority configuration
init-priority
```

## Working with the Proxy

### Start Proxy Manually

```powershell
# Start the Antigravity proxy
start-proxy

# Proxy runs on http://localhost:8081
```

**The proxy auto-starts when you:**
- Run `claude-free`
- Run `happy-free`
- Run `dual-sessions`

### Check Proxy Status

```powershell
# View current mode (shows if proxy is running)
claude-mode
```

**Example output:**
```
Current Claude Configuration:
   Mode: FREE (Antigravity Proxy)
   Using: Google accounts
   Proxy: Running ✓
```

### Stop Proxy

```powershell
# Find proxy process
Get-Process -Name node | Where-Object {$_.CommandLine -like "*antigravity*"}

# Stop it
Stop-Process -Name <PID>
```

## Daily Workflows

### Morning Routine

```powershell
# 1. Check quotas
check-usage

# 2. Choose mode based on availability
claude-free   # or claude-paid

# 3. Start working
claude "Good morning! Let's build something today."
```

### Switching During Work

```powershell
# Check if you need to switch
check-usage

# Switch modes as needed
claude-free
# or
claude-paid

# IMPORTANT: Exit current conversation first!
# In Claude CLI: /exit
# Then switch modes, then start new conversation
```

**⚠️ Warning:** Don't switch modes mid-conversation with thinking models! See [Troubleshooting](TROUBLESHOOTING.md) for details.

### Mobile Development Session

```powershell
# Start dual sessions for mobile access
dual-sessions

# Work from your desktop:
# - Use GREEN window for casual/experimental work (FREE)
# - Use BLUE window for production work (PAID)

# On mobile:
# - Scan both QR codes
# - Switch sessions in HappyCoder app as needed
```

### Remote Work (SSH)

```powershell
# SSH into your Windows machine
ssh user@your-ip

# Start tmux session
tmux new -s claude-work

# Set up your mode
claude-free

# Start HappyCoder for mobile access
happy-free

# Detach: Ctrl+B, D
# Reattach later: tmux attach -t claude-work
```

## Advanced Usage

### Custom Workflows

#### Batch Mode Switching

```powershell
# Script to switch based on quota
$usage = check-usage
if ($usage -match "0%") {
    claude-paid
} else {
    claude-free
}
```

#### Environment-Based Setup

```powershell
# Add to your profile for project-specific defaults
if (Test-Path ".\PROJECT_FREE") {
    claude-free
} else {
    claude-paid
}
```

### Keyboard Shortcuts

Add these to your PowerShell profile for quick access:

```powershell
# Quick aliases (already included if you used installer)
Set-PSReadLineKeyHandler -Chord 'Ctrl+Alt+F' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::InsertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('claude-free')
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Chord 'Ctrl+Alt+P' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::InsertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('claude-paid')
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
```

## Tips & Best Practices

### 1. Check Usage Regularly

```powershell
# Add this to your profile to show usage on startup
if ((Get-Date).Hour -eq 0 -and (Get-Date).Minute -lt 5) {
    check-usage
}
```

### 2. Set Smart Defaults

Configure priority to match your usage:
- Heavy free user? → `antigravity-first`
- Paid subscriber? → `claude-first`

### 3. Use Dual Sessions

For mobile development:
- Always use `dual-sessions` instead of individual sessions
- Symlinks make it easy to identify FREE vs PAID
- No need to stop/restart when switching

### 4. Respect Quota Limits

- Check `check-usage` before starting large tasks
- Switch to paid for critical work
- Use free for experimentation

### 5. Keep Conversations Fresh

When switching modes:
1. Exit current conversation (`/exit` in Claude CLI)
2. Switch mode (`claude-free` or `claude-paid`)
3. Start fresh conversation

### 6. Leverage Help System

```powershell
# Forgot a command?
claude-help

# Need details?
claude-help <command>
```

## Command Reference

| Command | Usage |
|---------|-------|
| `claude-help` | Show all commands or detailed help |
| `claude-mode` | Display current configuration |
| `check-usage` | View all account quotas |
| `claude-free` | Switch to FREE mode (Antigravity) |
| `claude-paid` | Switch to PAID mode (Claude Code) |
| `start-proxy` | Manually start Antigravity proxy |
| `get-priority` | View account priority order |
| `set-priority` | Change priority configuration |
| `init-priority` | Initialize priority (first time) |
| `happy-free` | Start HappyCoder with Antigravity |
| `happy-paid` | Start HappyCoder with Claude Code |
| `dual-sessions` | Start both FREE/PAID sessions |

## Next Steps

- **[Quick Reference](QUICK_REFERENCE.md)** - Command cheat sheet
- **[Remote Access](REMOTE_ACCESS.md)** - Mobile and SSH setup
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues
- **[Architecture](ARCHITECTURE.md)** - Technical details

Need help? Run `claude-help` anytime!
