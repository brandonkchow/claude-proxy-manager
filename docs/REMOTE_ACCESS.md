# Remote Access Guide

Complete guide for using Claude Proxy Manager remotely via SSH, tmux, and mobile workflows.

## Persistent Sessions with Happy Daemon (NEW!)

**The best way to use HappyCoder** is with persistent sessions that survive terminal restarts and computer reboots!

### What is Happy Daemon?

The happy daemon is a background service that keeps your HappyCoder sessions alive permanently:
- **Sessions persist** across terminal restarts
- **Sessions survive** computer reboots
- **One-time QR code scan** - sessions reconnect automatically
- **Auto-start on login** - configure during installation

### Quick Start: Persistent Dual Sessions

```powershell
# Start daemon (one time)
daemon-start

# Start persistent dual sessions (FREE + PAID)
dual-sessions -UseDaemon
```

**What this does:**
1. Ensures happy daemon is running
2. Creates two persistent sessions (FREE and PAID modes)
3. Displays QR codes for one-time scanning
4. Sessions remain active even after closing terminal windows

**In HappyCoder mobile app:**
- Sessions appear as `YourProject-FREE` and `YourProject-PAID`
- Tap to switch between them instantly
- Sessions reconnect automatically after reboots

### Daemon Management Commands

```powershell
# Check daemon status
daemon-status

# Start daemon
daemon-start

# Stop daemon (sessions persist on relay server!)
daemon-stop

# Restart daemon (safe - sessions survive)
daemon-restart
```

### Auto-Start Configuration

During installation, you can configure what auto-starts on Windows login:

**Option 1: None** - Just daemon (manual session start)
- Most flexible
- You control when sessions start
- Command: `daemon-start` runs at login

**Option 2: Dual** - Both FREE and PAID sessions
- Best for daily use
- Both sessions ready immediately after login
- One QR scan for each, permanent access

**Option 3: Free** - Only Antigravity session
- Save paid quota
- Free Google accounts always available
- Single session mode

**Option 4: Paid** - Only Claude Code session
- Best performance
- Paid account session ready
- Single session mode

**Changing Configuration:**
Re-run the installer or manually edit `~/.claude/claude-proxy-manager/daemon-config.json`

### How Sessions Persist

**Critical Understanding**: Sessions are stored on the happy-server relay (cloud), not locally.

- **Daemon stops** → Sessions remain active on relay
- **Computer reboots** → Sessions reconnect when daemon restarts
- **Terminal closes** → Sessions unaffected (daemon runs in background)
- **Network drops** → Sessions reconnect automatically

### Daemon vs Standard Mode

**Standard Mode** (without `-UseDaemon`):
```powershell
dual-sessions
```
- Sessions run in foreground
- Sessions die when you close the window
- Must rescan QR codes every time

**Persistent Mode** (with `-UseDaemon`):
```powershell
dual-sessions -UseDaemon
```
- Sessions run via daemon
- Sessions survive terminal restarts
- One-time QR code scan

### Troubleshooting Daemon

**Daemon not starting:**
```powershell
# Check if happy-coder is installed
happy --version

# Install if missing
npm install -g happy-coder

# Start daemon
daemon-start
```

**Sessions disappeared after reboot:**
```powershell
# Check daemon status
daemon-status

# Daemon should auto-start on login
# If not, check Task Scheduler task: "HappyCoderDaemon"
Get-ScheduledTask -TaskName "HappyCoderDaemon"

# Manually start if needed
daemon-start
```

**After updating happy-coder:**
```powershell
# Update the npm package
npm update -g happy-coder

# Restart daemon (sessions survive!)
daemon-restart
```

### Remote Access with Persistent Sessions

**Perfect Setup**: Tailscale + Daemon + Dual Sessions

```bash
# ONE-TIME SETUP (on Windows machine):

# 1. Enable daemon auto-start (done during installation)
# 2. Configure for dual sessions
# 3. Start persistent sessions
dual-sessions -UseDaemon

# 4. Scan QR codes on mobile (one time only!)

# NOW FOREVER:
# - Close laptop → Sessions stay alive
# - Reboot computer → Sessions reconnect
# - Travel anywhere → Access via mobile
# - No rescanning needed!
```

**Session Management Over SSH:**
```bash
# SSH into Windows machine
ssh user@100.x.x.x  # Tailscale IP

# Check daemon status
daemon-status

# View active sessions (managed by daemon)
happy daemon status

# Restart daemon if needed (sessions survive)
daemon-restart
```

---

## Quick Start: Dual Sessions (RECOMMENDED)

The easiest way to access Claude on mobile is with the **dual-sessions** command:

```powershell
# Standard mode (foreground sessions)
dual-sessions

# Persistent mode (sessions survive restarts) - RECOMMENDED!
dual-sessions -UseDaemon
```

**What this does:**
1. Creates two symlinked directories (`YourProject-FREE` and `YourProject-PAID`)
2. Opens two PowerShell windows (GREEN for FREE, BLUE for PAID)
3. Displays QR codes in each window
4. Sessions appear as distinct entries in HappyCoder mobile app
5. With `-UseDaemon`: Sessions persist across terminal/computer restarts

**First-time symlink setup:**
```powershell
# If symlinks fail, enable Developer Mode (one-time, requires admin):
.\enable-symlinks.ps1

# OR use the elevated version:
.\dual-sessions-elevated.ps1
```

After first setup, symlinks persist and no admin rights needed!

**In HappyCoder app you'll see:**
- `YourProject-FREE` (Antigravity - free Google accounts)
- `YourProject-PAID` (Claude Code - paid account)

Simply tap to switch between FREE and PAID modes!

**For best experience**: Use `dual-sessions -UseDaemon` to ensure your sessions stay alive permanently.

---

## SSH Setup

> [!TIP]
> The installer can set this up automatically! When running the installer, choose "Yes" for Step 9 (Remote Access Setup).

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

## psmux for Persistent Sessions

> [!TIP]
> The installer can install psmux automatically! Choose "Yes" for Step 9 (Remote Access Setup).

### Why psmux?
`psmux` is a native Windows terminal multiplexer that works exactly like `tmux`. It allows you to:
- Keep Claude sessions running when you disconnect
- Resume exactly where you left off
- Manage multiple sessions (e.g., free vs paid)

### Installation

If you didn't use the installer, you can install it via Chocolatey:

```powershell
choco install psmux -y
```

### Basic Commands (Same as tmux!)

| Action | Command |
|--------|---------|
| Start new session | `psmux` |
| Start named session | `psmux new -s my-session` |
| Detach from session | `Ctrl+b` then `d` |
| List sessions | `psmux ls` |
| Attach to session | `psmux attach -t my-session` |
| Kill session | `psmux kill-session -t my-session` |

> [!NOTE]
> `psmux` installs a `tmux` alias, so you can just type `tmux` if you prefer!
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

> [!TIP]
> The installer can set up HappyCoder automatically! Choose "Yes" for Step 9 (Remote Access Setup) to install HappyCoder CLI and create convenient aliases.

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

> [!NOTE]
> If you chose "Yes" for remote access setup during installation, HappyCoder CLI is already installed and aliases are configured!

#### 1. Install HappyCoder CLI (Manual)

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

#### Switching Modes Remotely (Out of Town)

If you're away from your Windows machine and want to switch modes:

**Option 1: SSH + Restart HappyCoder** (Recommended)
```bash
# 1. SSH into your Windows machine (via Tailscale)
ssh user@100.x.x.x

# 2. Find and stop running HappyCoder
ps aux | grep happy
kill <process-id>

# 3. Switch mode
claude-free  # or claude-paid

# 4. Restart HappyCoder
happy-proxy  # or happy

# 5. Scan new QR code on mobile
# 6. Continue with new mode!
```

**Option 2: Use Dual Sessions (RECOMMENDED - Best Mobile Experience)**
```powershell
# EASIEST: Just run the dual-sessions command
dual-sessions

# This will:
# 1. Create symlinked directories (myproject-FREE and myproject-PAID)
# 2. Start proxy if needed
# 3. Open two color-coded windows (GREEN = FREE, BLUE = PAID)
# 4. Display QR codes for both sessions

# In HappyCoder mobile app, you'll see:
# 🟢 myproject-FREE  ← Free Antigravity session
# 🔵 myproject-PAID  ← Paid Claude Code session

# Advanced options:
dual-sessions -SessionName "MyWork"  # Custom session name
dual-sessions -NoSymlinks            # Disable symlinks (not recommended)
```

**Option 3: Manual Separate Sessions**
```powershell
# On Windows, create two tmux sessions manually:

# Session 1: FREE mode
tmux new -s happy-free
start-proxy
happy-free
# Ctrl+B, D to detach

# Session 2: PAID mode
tmux new -s happy-paid
happy-paid
# Ctrl+B, D to detach

# From mobile:
# - Scan QR from happy-free for Antigravity
# - Scan QR from happy-paid for Claude Code
# - Switch between them in HappyCoder app!
```

**Option 4: Remote Desktop** (When dual-sessions isn't available)
```
# Use Windows Remote Desktop or Chrome Remote Desktop
# 1. Connect to Windows machine
# 2. Stop HappyCoder (Ctrl+C)
# 3. Switch mode in terminal
# 4. Restart HappyCoder
# 5. Scan new QR code
```

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
