# Troubleshooting Guide

Solutions to common issues with Claude Proxy Manager.

## Quick Diagnostics

```powershell
# Run these commands to diagnose issues:
claude-mode        # Check current mode
check-usage        # Verify accounts are detected
get-priority       # Check priority configuration
claude-help        # Ensure commands are loaded
```

## Common Issues

### Mode Switching Issues

#### "Thinking blocks" causing API errors

**Problem:** Switched modes mid-conversation and getting 400 errors

**Cause:** Antigravity proxy cannot process "thinking blocks" from Claude's thinking models (`-thinking` suffix)

**Solution:**
```powershell
# 1. Exit current conversation
# In Claude CLI, type: /exit

# 2. Switch modes
claude-free  # or claude-paid

# 3. Start fresh conversation
claude "Hello!"
```

**Prevention:** Always exit conversations before switching modes!

#### Mode switch doesn't take effect

**Problem:** Ran `claude-free` but still using paid mode

**Solution:**
```powershell
# Reload your PowerShell profile
. $PROFILE

# Or restart PowerShell window
```

**Check if it worked:**
```powershell
claude-mode
# Should show: "Mode: FREE (Antigravity Proxy)"
```

### Proxy Issues

#### Proxy won't start

**Problem:** `start-proxy` fails or proxy doesn't respond

**Diagnosis:**
```powershell
# Check if port 8081 is already in use
netstat -ano | findstr :8081
```

**Solution 1 - Kill conflicting process:**
```powershell
# Find PID from netstat output
taskkill /PID <pid> /F

# Then start proxy again
start-proxy
```

**Solution 2 - Use different port:**
```powershell
# Use custom port
$env:PORT = '8082'
start-proxy

# Update settings.json to use new port
# Edit: ~/.claude/settings.json
# Change: "ANTHROPIC_BASE_URL": "http://localhost:8082"
```

#### Proxy running but not responding

**Problem:** Proxy is running but `check-usage` shows "Proxy not running"

**Solution:**
```powershell
# Test proxy directly
Invoke-WebRequest -Uri "http://localhost:8081/health" -UseBasicParsing

# If that fails, restart proxy:
# 1. Kill proxy process
Get-Process -Name node | Where-Object {$_.Path -like "*antigravity*"} | Stop-Process

# 2. Start fresh
start-proxy
```

### Symlink Issues (dual-sessions)

#### Symlinks fail to create

**Problem:** `dual-sessions` shows "Failed to create symlink (may need admin rights)"

**Cause:** Windows requires admin rights or Developer Mode for symlinks

**Solution 1 - Enable Developer Mode (RECOMMENDED):**
```powershell
# Run as Administrator (one-time setup):
.\enable-symlinks.ps1

# Then log out and log back in
```

**Solution 2 - Use elevated version:**
```powershell
# This will prompt for UAC each time
.\dual-sessions-elevated.ps1
```

**Solution 3 - Run as Administrator:**
```powershell
# Right-click PowerShell → "Run as Administrator"
dual-sessions
```

**Verify symlinks exist:**
```powershell
Get-Item C:\Users\<yourname>\GitHub\*-FREE | Select-Object LinkType, Target
Get-Item C:\Users\<yourname>\GitHub\*-PAID | Select-Object LinkType, Target
```

#### Symlinks point to wrong directory

**Problem:** Symlinks created but point to wrong location

**Solution:**
```powershell
# Remove old symlinks
Remove-Item "path\to\project-FREE" -Force
Remove-Item "path\to\project-PAID" -Force

# Navigate to correct directory
cd C:\path\to\your\project

# Run dual-sessions again
dual-sessions
```

### HappyCoder / Mobile Issues

#### QR code won't scan

**Problem:** HappyCoder app can't scan QR code

**Solutions:**
- Ensure phone and computer are on same network
- Check Windows Firewall isn't blocking HappyCoder port
- Try rescanning - sometimes takes 2-3 attempts
- Increase window size to make QR code larger

#### Sessions appear identical in app

**Problem:** Both FREE and PAID show same name in HappyCoder

**Cause:** Symlinks weren't created

**Solution:**
```powershell
# Enable Developer Mode first
.\enable-symlinks.ps1

# Log out and log back in to Windows

# Run dual-sessions again
dual-sessions
```

**Verify symlinks:**
```powershell
# Check parent directory
ls C:\path\to\ | Where-Object {$_.Name -like "*-FREE" -or $_.Name -like "*-PAID"}
```

#### Can't connect to session

**Problem:** HappyCoder shows "Connection failed"

**Diagnosis:**
```powershell
# Check if HappyCoder is still running
Get-Process -Name node | Where-Object {$_.Path -like "*happy*"}
```

**Solution:**
```powershell
# Restart the session
# 1. Close the QR code window
# 2. Run dual-sessions again
dual-sessions
```

### Priority Configuration Issues

#### `check-usage` shows no accounts

**Problem:** "Run: init-priority to set up priority order"

**Solution:**
```powershell
# Initialize priority configuration
init-priority

# Choose default: antigravity-first or claude-first
# Accounts will be auto-detected
```

#### Priority order not working

**Problem:** Wrong account being used despite priority settings

**Diagnosis:**
```powershell
# Check priority config
get-priority

# Check if accounts are enabled
cat ~/.claude/priority.json
```

**Solution:**
```powershell
# Reconfigure priority
set-priority

# Or manually edit:
notepad ~/.claude/priority.json

# Ensure "enabled": true for accounts you want to use
```

### Command Not Found Errors

#### `claude-help: command not found`

**Problem:** Commands not available after installation

**Cause:** PowerShell profile not reloaded

**Solution:**
```powershell
# Reload profile
. $PROFILE

# Or restart PowerShell window
```

**Verify profile is loaded:**
```powershell
# Check if functions exist
Get-Command claude-help
Get-Command dual-sessions

# If not found, check profile integration:
cat $PROFILE
# Should contain: . "$env:USERPROFILE\.claude\claude-proxy-manager\profile-snippet.ps1"
```

#### `dual-sessions: command not found`

**Problem:** Specific command missing

**Solution:**
```powershell
# Re-run installer to update scripts
iwr -useb https://raw.githubusercontent.com/brandonkchow/claude-proxy-manager/main/scripts/install.ps1 | iex

# Reload profile
. $PROFILE
```

### Quota and Usage Issues

#### `check-usage` shows 0% for all accounts

**Problem:** All Google accounts show exhausted

**Solutions:**
- Wait for quota reset (shows reset time in `check-usage`)
- Switch to paid mode: `claude-paid`
- Add more Google accounts to Antigravity proxy

#### Can't switch to paid mode

**Problem:** `claude-paid` doesn't work

**Diagnosis:**
```powershell
# Check if Claude Code CLI is installed
claude --version

# Check authentication
claude /login
```

**Solution:**
```powershell
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Authenticate
claude /login

# Try switching again
claude-paid
```

### Performance Issues

#### Slow response times

**Possible causes:**
1. **Proxy overhead** - Antigravity adds latency
2. **Network issues** - Check internet connection
3. **Quota exhaustion** - Falling back to slower model

**Solutions:**
```powershell
# Switch to paid for better performance
claude-paid

# Check which account is being used
check-usage

# Restart proxy if it's been running long
Get-Process -Name node | Where-Object {$_.Path -like "*antigravity*"} | Stop-Process
start-proxy
```

#### PowerShell freezes when switching modes

**Problem:** PowerShell hangs when running `claude-free` or `claude-paid`

**Solution:**
```powershell
# 1. Kill PowerShell process
# Press Ctrl+C

# 2. Restart PowerShell

# 3. Try again without reloading profile
claude-free  # Don't run ". $PROFILE" in the mode switch script
```

**Fix in profile-snippet.ps1:**
```powershell
# Remove ". $PROFILE" line from Use-ClaudeFree and Use-ClaudePaid functions
# Edit: ~/.claude/claude-proxy-manager/profile-snippet.ps1
```

## Error Messages

### "Administrator privilege required for this operation"

**Context:** Creating symlinks

**Solution:** See [Symlink Issues](#symlinks-fail-to-create) above

### "execution of scripts is disabled on this system"

**Context:** Running PowerShell scripts

**Solution:**
```powershell
# Run as Administrator
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Cannot process 'thinking blocks'"

**Context:** Using Antigravity proxy with thinking models

**Solution:** Exit conversation, stay in same mode, and start fresh conversation

Or switch to paid mode:
```powershell
claude-paid
```

### "Port 8081 already in use"

**Context:** Starting Antigravity proxy

**Solution:** See [Proxy won't start](#proxy-wont-start) above

## Getting More Help

### Enable Debug Mode

```powershell
# Run Claude with debug output
claude -d "api,hooks"
```

### Check Logs

```powershell
# Antigravity proxy logs
cat ~/.antigravity-claude-proxy/logs/*

# HappyCoder logs
cat ~/.happy/logs/*
```

### Reinstall

If all else fails:

```powershell
# 1. Remove old installation
Remove-Item -Recurse -Force ~/.claude/claude-proxy-manager

# 2. Re-run installer
iwr -useb https://raw.githubusercontent.com/brandonkchow/claude-proxy-manager/main/scripts/install.ps1 | iex

# 3. Reload profile
. $PROFILE
```

### Report an Issue

Still stuck? Report an issue:

1. Run diagnostics:
```powershell
claude-mode
check-usage
get-priority
claude --version
node --version
```

2. Copy output and create issue at:
   https://github.com/brandonkchow/claude-proxy-manager/issues

3. Include:
   - PowerShell version: `$PSVersionTable.PSVersion`
   - Windows version: `[System.Environment]::OSVersion.Version`
   - Error messages
   - Steps to reproduce

## Prevention Tips

### Regular Maintenance

```powershell
# Weekly: Check for updates
iwr -useb https://raw.githubusercontent.com/brandonkchow/claude-proxy-manager/main/scripts/install.ps1 | iex

# Daily: Monitor quotas
check-usage

# Before important work: Verify mode
claude-mode
```

### Best Practices

1. **Always exit conversations before switching modes**
2. **Enable Developer Mode for seamless symlinks**
3. **Keep Antigravity proxy running for FREE mode**
4. **Use `dual-sessions` for mobile instead of manual setup**
5. **Run `claude-help` when you forget commands**

## Related Documentation

- **[Quick Reference](QUICK_REFERENCE.md)** - Command cheat sheet
- **[Setup Guide](SETUP.md)** - Installation help
- **[Usage Guide](USAGE.md)** - Daily workflows
- **[Remote Access](REMOTE_ACCESS.md)** - Mobile setup

---

**Still need help?** Run `claude-help` or open an issue on GitHub!
