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

### Option 1: Tailscale (Recommended)

**Why Tailscale?**
- Zero configuration
- Works from anywhere
- Secure encrypted tunnel
- No port forwarding needed
- Free for personal use

**Setup**:
1. Install Tailscale on Windows machine: https://tailscale.com/download
2. Install Tailscale on mobile device
3. Both devices join same Tailscale network

**Usage**:
```bash
# Get your Windows Tailscale IP
tailscale ip
# Example: 100.101.102.103

# SSH from anywhere in the world
ssh user@100.101.102.103

# Or use with HappyCoder
# HappyCoder uses its own relay, but Tailscale ensures
# your Windows machine is always reachable
```

**With tmux + Tailscale**:
```bash
# At home: Start session
ssh user@100.101.102.103
tmux new -s claude
start-proxy
claude
# Ctrl+B, D to detach

# In another city: Resume session
ssh user@100.101.102.103
tmux attach -s claude
# Continue exactly where you left off!
```

### Option 2: SSH Tunnel

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

## HappyCoder Integration

### What is HappyCoder?

HappyCoder is a **free, open-source mobile client** for Claude Code that enables real-time synchronization between your desktop and mobile device. Perfect for continuing your coding sessions anywhere!

**Key Features:**
- Real-time bidirectional sync between desktop and mobile
- End-to-end encryption with QR code pairing
- Multi-session management
- Works seamlessly with Claude Code CLI
- Voice agent integration
- Push notifications

### Installation

#### 1. Install HappyCoder CLI

```powershell
npm install -g happy-coder
```

**Requirements:**
- Node.js >= 20.0.0
- Claude Code CLI installed and authenticated

#### 2. Install Mobile App

- **Android**: [Google Play Store](https://play.google.com/store/apps/details?id=com.ex3ndr.happy)
- **iOS**: Search "Happy Coder" in App Store

### Setup with Claude Proxy Manager

HappyCoder works **perfectly** with Claude Proxy Manager! Here's how to set it up:

> [!CAUTION]
> **Thinking Model Incompatibility Warning**
> 
> Do NOT switch between paid Claude Code and Antigravity proxy in the same HappyCoder session. The proxy cannot process "thinking blocks" from Claude's extended thinking models.
> 
> **If you need to switch modes**:
> 1. Exit current conversation: `/exit`
> 2. Stop HappyCoder (Ctrl+C)
> 3. Switch mode: `claude-free` or `claude-paid`
> 4. Restart HappyCoder
> 5. Scan new QR code
> 
> **Best Practice**: Choose one mode and stick with it for the entire session.

#### Option 1: Use with Antigravity Proxy (Recommended)

```powershell
# 1. Start Antigravity proxy
start-proxy

# 2. Switch to FREE mode (if not already)
claude-free

# 3. Start HappyCoder with environment variables
happy --claude-env ANTHROPIC_AUTH_TOKEN=test --claude-env ANTHROPIC_BASE_URL=http://localhost:8081
```

#### Option 2: Use with Paid Claude Code

```powershell
# 1. Switch to PAID mode
claude-paid

# 2. Start HappyCoder normally
happy
```

### Complete Setup Workflow

```powershell
# 1. Check your current mode
claude-mode

# 2. Ensure proxy is running (for FREE mode)
check-usage

# 3. Start HappyCoder with proxy support
happy --claude-env ANTHROPIC_AUTH_TOKEN=test --claude-env ANTHROPIC_BASE_URL=http://localhost:8081

# 4. Scan QR code with mobile app
# The QR code will appear in your terminal

# 5. Start coding on mobile or desktop!
```

### HappyCoder Commands

```bash
# Start Claude Code session with QR code
happy

# Start with specific model
happy --model opus

# Manage authentication
happy auth

# System diagnostics
happy doctor

# Send push notification to devices
happy notify "Build completed!"

# Manage background daemon
happy daemon start
happy daemon stop
happy daemon status
```

### Environment Variables for Proxy

When using HappyCoder with Antigravity proxy, pass these environment variables:

```powershell
# Required for proxy mode
--claude-env ANTHROPIC_AUTH_TOKEN=test
--claude-env ANTHROPIC_BASE_URL=http://localhost:8081

# Optional: Specify model
--claude-env ANTHROPIC_MODEL=claude-sonnet-4-5
```

### Creating a Convenient Alias

Add to your PowerShell profile for easy access:

```powershell
# Add to $PROFILE
function Start-HappyProxy {
    Write-Host "Starting HappyCoder with Antigravity proxy..." -ForegroundColor Cyan
    happy --claude-env ANTHROPIC_AUTH_TOKEN=test --claude-env ANTHROPIC_BASE_URL=http://localhost:8081
}

Set-Alias -Name happy-proxy -Value Start-HappyProxy
```

Now you can just run:
```powershell
happy-proxy
```

### Mobile Workflow with HappyCoder

1. **Start Session on Desktop**
   ```powershell
   happy-proxy
   ```

2. **Scan QR Code** with HappyCoder mobile app

3. **Continue on Mobile**
   - Type messages on your phone
   - See responses in real-time
   - Full conversation history synced

4. **Switch Back to Desktop**
   - Same session continues
   - No context loss
   - Seamless transition

### Advanced: HappyCoder + tmux

For the ultimate remote coding setup:

```bash
# 1. SSH into your Windows machine
ssh bchow@192.168.1.100

# 2. Start tmux session
tmux new -s happy-claude

# 3. Start proxy
start-proxy

# 4. Start HappyCoder
happy-proxy

# 5. Scan QR code with mobile app

# 6. Detach from tmux (session keeps running)
# Ctrl+B, D

# Now you can:
# - Close SSH connection
# - Use mobile app anywhere
# - Reconnect to tmux later
# - Session persists!
```

### Troubleshooting HappyCoder

#### QR Code Not Appearing

```powershell
# Check Claude Code is installed
claude --version

# Check Node.js version (must be >= 20)
node --version

# Run diagnostics
happy doctor
```

#### Proxy Connection Issues

```powershell
# Verify proxy is running
Test-NetConnection -ComputerName localhost -Port 8081

# Check proxy status
check-usage

# Restart proxy
# Stop any running proxy first, then:
start-proxy
```

#### Mobile App Not Connecting

1. **Check QR Code**: Make sure you scanned the full QR code
2. **Network**: Ensure mobile device can reach your computer
3. **Firewall**: Check Windows Firewall isn't blocking HappyCoder
4. **Restart**: Close mobile app and rescan QR code

#### Environment Variables Not Working

```powershell
# Verify variables are being passed
happy --claude-env ANTHROPIC_BASE_URL=http://localhost:8081 --help

# Check if proxy is accessible
Invoke-WebRequest -Uri "http://localhost:8081/health"
```

### HappyCoder with Priority System

HappyCoder works with your priority configuration:

```powershell
# View current priority
get-priority

# If Antigravity is first priority
happy-proxy  # Uses proxy automatically

# If Claude Code is first priority
happy  # Uses paid account
```

### Security Notes

- **End-to-End Encryption**: All data encrypted between desktop and mobile
- **QR Code Pairing**: Secure key exchange via QR code
- **Zero-Trust**: Relay server cannot read your data
- **Self-Hosting**: Can host your own relay server if desired

### Resources

- **GitHub**: [slopus/happy-cli](https://github.com/slopus/happy-cli)
- **Documentation**: [happy.engineering](https://happy.engineering)
- **Mobile App**: [Google Play](https://play.google.com/store/apps/details?id=com.ex3ndr.happy)

---

**Pro Tip**: Create a PowerShell function that starts proxy, waits for it to be ready, then launches HappyCoder:

```powershell
function Start-HappyComplete {
    Write-Host "Starting complete HappyCoder setup..." -ForegroundColor Cyan
    
    # Start proxy in background
    Start-Job -ScriptBlock { 
        $env:PORT = '8081'
        antigravity-claude-proxy start --fallback 
    } | Out-Null
    
    # Wait for proxy to be ready
    Write-Host "Waiting for proxy..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    
    # Start HappyCoder
    Write-Host "Starting HappyCoder..." -ForegroundColor Green
    happy --claude-env ANTHROPIC_AUTH_TOKEN=test --claude-env ANTHROPIC_BASE_URL=http://localhost:8081
}
```

---

**Pro Tip**: Create a shell alias for quick connection:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias claude-remote="ssh bchow@192.168.1.100 -t 'tmux attach -s claude || tmux new -s claude'"

# Now just run:
claude-remote
```
