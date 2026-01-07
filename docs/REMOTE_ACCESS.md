# Remote Access Guide

Complete guide for using Claude Proxy Manager remotely via SSH, tmux, and mobile workflows.

## SSH Setup

### Prerequisites
- SSH server running on your Windows machine
- SSH client on remote device (built-in on Mac/Linux/iOS)

### Windows SSH Server Setup

```powershell
# Install OpenSSH Server (Windows 10/11)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start and enable SSH service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Configure firewall
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

### Connect from Remote Device

```bash
# From Mac/Linux/iOS (using terminal apps like Termius, Blink)
ssh username@your-windows-ip

# Example
ssh bchow@192.168.1.100
```

## tmux for Persistent Sessions

### Why tmux?
- Keep Claude sessions running when you disconnect
- Resume exactly where you left off
- Multiple windows for different projects

### Install tmux on Windows

```powershell
# Using Chocolatey
choco install tmux

# Or using Scoop
scoop install tmux
```

### Basic tmux Workflow

```bash
# Start new session
tmux new -s claude

# Inside tmux, start Claude
claude

# Detach from session (keeps running)
# Press: Ctrl+B, then D

# List sessions
tmux ls

# Reattach to session
tmux attach -s claude
```

### tmux Cheat Sheet

```
Ctrl+B, then:
  C       Create new window
  N       Next window
  P       Previous window
  D       Detach session
  [       Scroll mode (q to exit)
  %       Split vertically
  "       Split horizontally
```

## Mobile Workflows

### iOS Setup

**Recommended Apps:**
1. **Termius** (Free, best UX)
2. **Blink Shell** (Paid, advanced features)
3. **iSH** (Local Linux shell)

**Workflow:**
1. Install Termius from App Store
2. Add new host:
   - Hostname: Your Windows IP
   - Username: Your Windows username
   - Port: 22
3. Connect and start tmux session
4. Use Claude normally

### Android Setup

**Recommended Apps:**
1. **Termux** (Free, full terminal)
2. **JuiceSSH** (Free, SSH client)

**Workflow:**
1. Install Termux or JuiceSSH
2. Connect via SSH
3. Use tmux for persistence

## Claude Proxy Manager Remote Best Practices

### 1. Use Antigravity-First Priority

For remote workflows, Antigravity-first is recommended:
- Avoids thinking model conversation conflicts
- Better for resuming sessions
- No need to switch modes manually

```powershell
# Set priority to Antigravity-first
set-priority
# Choose option 2
```

### 2. Auto-Start Proxy

Ensure proxy starts automatically:

```powershell
# Add to PowerShell profile
if (-not (Test-NetConnection -ComputerName localhost -Port 8081 -InformationLevel Quiet -WarningAction SilentlyContinue)) {
    Start-AntigravityProxy &
}
```

### 3. Check Status Before Starting

```powershell
# Quick status check
check-usage

# Verify proxy is running
claude-mode
```

### 4. Use tmux Sessions

```bash
# Create dedicated Claude session
tmux new -s claude-work

# Start Claude
claude

# Detach when done
# Ctrl+B, D

# Resume later
tmux attach -s claude-work
```

## Troubleshooting

### SSH Connection Refused

```powershell
# Check if SSH service is running
Get-Service sshd

# Start if stopped
Start-Service sshd
```

### Proxy Not Running After Reconnect

```powershell
# Check proxy status
Test-NetConnection -ComputerName localhost -Port 8081

# Start if needed
start-proxy
```

### tmux Session Lost

```bash
# List all sessions
tmux ls

# If no sessions, they were killed
# Check if tmux server is running
ps aux | grep tmux

# Restart tmux server if needed
tmux kill-server
tmux new -s claude
```

## Advanced: Port Forwarding

If you're outside your home network:

### Option 1: SSH Tunnel

```bash
# Forward local port 8081 to remote proxy
ssh -L 8081:localhost:8081 username@remote-ip

# Now access proxy at localhost:8081
```

### Option 2: VPN

- Use Tailscale, ZeroTier, or WireGuard
- Access your Windows machine as if on local network

## Security Considerations

1. **Use SSH Keys** instead of passwords
2. **Change default SSH port** (22 → custom)
3. **Enable Windows Firewall** rules
4. **Use VPN** for external access
5. **Keep sessions private** - don't share tmux sessions

## Example Complete Workflow

```bash
# 1. SSH into Windows machine
ssh bchow@192.168.1.100

# 2. Start or attach to tmux session
tmux attach -s claude || tmux new -s claude

# 3. Check Claude status
check-usage

# 4. Start proxy if needed
start-proxy

# 5. Start Claude
claude

# 6. Work on your project
# ...

# 7. Detach when done (keeps running)
# Ctrl+B, D

# 8. Exit SSH
exit

# Later: Reconnect and resume
ssh bchow@192.168.1.100
tmux attach -s claude
# Continue exactly where you left off!
```

## Happy Coder Integration

> [!NOTE]
> Happy Coder integration documentation will be added in a future update.
> For now, Happy Coder can connect to Claude Code CLI through standard SSH workflows.

---

**Pro Tip**: Create a shell alias for quick connection:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias claude-remote="ssh bchow@192.168.1.100 -t 'tmux attach -s claude || tmux new -s claude'"

# Now just run:
claude-remote
```
