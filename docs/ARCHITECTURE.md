# Architecture Guide

Technical overview of how Claude Proxy Manager works under the hood.

## Overview

Claude Proxy Manager is a PowerShell-based tool that manages routing between:
- **Paid Mode:** Direct Anthropic API via Claude Code CLI
- **FREE Mode:** Google accounts via Antigravity proxy

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User (PowerShell)                        │
│  Commands: claude-free, claude-paid, dual-sessions, etc.   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     v
┌─────────────────────────────────────────────────────────────┐
│              Claude Proxy Manager                            │
│  • Mode switching (settings.json manipulation)              │
│  • Priority management (priority.json)                      │
│  • Proxy lifecycle (start/stop)                             │
│  • Profile integration (PowerShell functions)               │
└─────┬──────────────────────────────────┬────────────────────┘
      │                                  │
      v                                  v
┌─────────────────┐            ┌──────────────────────┐
│  PAID MODE      │            │  FREE MODE           │
│  Claude Code    │            │  Antigravity Proxy   │
│  Direct API     │            │  localhost:8081      │
└────────┬────────┘            └──────────┬───────────┘
         │                                │
         v                                v
┌─────────────────┐            ┌──────────────────────┐
│  Anthropic API  │            │  Google Accounts     │
│  (Paid)         │            │  → Claude AI Studio  │
└─────────────────┘            │  → Gemini (fallback) │
                               └──────────────────────┘
```

## Core Components

### 1. Mode Switcher (`switch-claude-mode.ps1`)

**Purpose:** Updates Claude Code settings to route requests

**PAID Mode:**
```json
{
  "env": {}
}
```
- No environment variables
- Claude CLI uses default Anthropic API
- Requires authentication with Claude Code

**FREE Mode:**
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8081",
    "ANTHROPIC_AUTH_TOKEN": "test"
  }
}
```
- Overrides API endpoint to localhost proxy
- Dummy token (proxy handles real auth)
- Routes through Antigravity proxy

### 2. Priority Manager (`priority-functions.ps1`)

**Purpose:** Defines account fallback order

**Data Structure:**
```json
{
  "defaultPriority": "antigravity-first",
  "priority": [
    {
      "type": "antigravity",
      "email": "user@gmail.com",
      "enabled": true
    },
    {
      "type": "claude-code",
      "enabled": true
    }
  ]
}
```

**Functions:**
- `Initialize-ClaudePriority` - Auto-detect accounts and create config
- `Get-ClaudePriority` - Display current order
- `Set-ClaudePriority` - Interactive priority editor

### 3. Profile Integration (`profile-snippet.ps1`)

**Purpose:** Provides PowerShell commands and automatic mode detection

**Key Functions:**
- `Use-ClaudePaid` / `Use-ClaudeFree` - Mode switching
- `Get-ClaudeMode` - Display current configuration
- `Check-ClaudeUsage` - Query all account quotas
- `Start-DualSessions` - HappyCoder dual-session setup
- `Show-ClaudeHelp` - Built-in help system

**Profile Hook:**
```powershell
# Added to $PROFILE by installer
. "$env:USERPROFILE\.claude\claude-proxy-manager\profile-snippet.ps1"
```

### 4. Antigravity Proxy Integration

**Proxy API Endpoints:**
- `GET /health` - Health check
- `GET /account-limits?format=json` - Quota information
- `POST /v1/messages` - Claude API proxy

**How it works:**
1. Proxy intercepts Claude API requests
2. Rotates through configured Google accounts
3. Falls back to Gemini if Claude quota exhausted
4. Returns response in Claude API format

## HappyCoder Integration

### Dual-Sessions Architecture

```
Working Directory: C:\Projects\MyApp
         │
         ├─ Symlink: MyApp-FREE → MyApp (created by dual-sessions)
         │   └─ PowerShell Window (GREEN bg)
         │       └─ happy --claude-env ANTHROPIC_BASE_URL=http://localhost:8081
         │
         └─ Symlink: MyApp-PAID → MyApp
             └─ PowerShell Window (BLUE bg)
                 └─ happy (default Anthropic API)
```

**Why symlinks?**
- HappyCoder identifies sessions by directory path
- Symlinks create distinct paths while sharing same files
- Appears as two sessions in mobile app:
  - `MyApp-FREE`
  - `MyApp-PAID`

### Session Identification

**Without symlinks:**
- Both sessions: `MyApp`
- Indistinguishable in HappyCoder app
- User must remember which QR code is which

**With symlinks:**
- FREE session: `MyApp-FREE`
- PAID session: `MyApp-PAID`
- Clear distinction in app session list

## File Structure

```
~/.claude/
├── settings.json              # Claude Code configuration
│                              # Managed by mode switcher
│
├── priority.json              # Account priority order
│                              # Managed by priority functions
│
└── claude-proxy-manager/
    ├── scripts/
    │   ├── switch-claude-mode.ps1    # Mode switching logic
    │   └── priority-functions.ps1     # Priority management
    │
    └── profile-snippet.ps1    # PowerShell functions and aliases

$PROFILE                       # User's PowerShell profile
                               # Sources profile-snippet.ps1
```

## Data Flow

### Mode Switch (FREE)

```
User: claude-free
    ↓
Use-ClaudeFree()
    ↓
switch-claude-mode.ps1free
    ↓
1. Read current settings.json
2. Backup to settings.json.bak
3. Set ANTHROPIC_BASE_URL=http://localhost:8081
4. Set ANTHROPIC_AUTH_TOKEN=test
5. Write settings.json
    ↓
Check proxy status
    ↓
If not running: Start-AntigravityProxy()
    ↓
Reload PowerShell profile
    ↓
Get-ClaudeMode() shows: "Mode: FREE"
```

### API Request Flow (FREE Mode)

```
User: claude "Hello"
    ↓
Claude CLI reads settings.json
    ↓
Sees ANTHROPIC_BASE_URL=http://localhost:8081
    ↓
Sends POST to http://localhost:8081/v1/messages
    ↓
Antigravity Proxy receives request
    ↓
Checks priority.json for account order
    ↓
Tries first enabled Google account
    ↓
If quota available:
  → Forward to Claude AI Studio
  → Return response
    ↓
If quota exhausted:
  → Try next account or fallback to Gemini
  → Return response
    ↓
Claude CLI receives response
    ↓
Displays to user
```

## Security Considerations

### Authentication

**PAID Mode:**
- Uses Claude Code authentication
- Token stored securely by Claude CLI
- Direct connection to Anthropic

**FREE Mode:**
- Proxy uses Google OAuth tokens
- Stored in `~/.antigravity-claude-proxy/`
- Never exposed to Claude CLI (dummy token "test")

### Network Security

- Proxy runs on `localhost:8081` (not exposed externally)
- HappyCoder uses SSH tunneling for remote access
- No credentials stored in settings.json

## Performance Characteristics

### Latency

**PAID Mode:**
- Direct API: ~500-1500ms (depends on model)
- No proxy overhead

**FREE Mode:**
- Proxy overhead: +50-200ms
- Google AI Studio: ~800-2000ms
- Total: ~850-2200ms

### Throughput

**PAID Mode:**
- Limited by Anthropic rate limits
- Varies by subscription tier

**FREE Mode:**
- Limited by Google AI Studio quotas
- Per-account limits (resets daily)
- Automatic fallback extends capacity

## Error Handling

### Mode Switch Failures

- Backup settings.json before modifications
- Restore from .bak if write fails
- Validate JSON before applying changes

### Proxy Failures

- Health check before routing to proxy
- Fallback message if proxy unreachable
- Auto-restart capability

### Quota Exhaustion

- Automatic account rotation
- Fallback from Claude → Gemini
- User notification via `check-usage`

## Extensibility

### Adding New Modes

1. Update `switch-claude-mode.ps1` with new mode logic
2. Add corresponding function in `profile-snippet.ps1`
3. Update priority.json schema if needed
4. Create alias for convenience

### Custom Proxy Configurations

Edit settings.json manually:
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://custom-proxy:3000",
    "ANTHROPIC_AUTH_TOKEN": "custom-token"
  }
}
```

## Dependencies

### Required

- **PowerShell 5.1+** - Script execution
- **Node.js 18+** - Runs proxies and CLIs
- **@anthropic-ai/claude-code** - Claude CLI
- **antigravity-claude-proxy** - Proxy server

### Optional

- **happy-coder** - Mobile access
- **psmux** - Terminal multiplexer
- **OpenSSH Server** - Remote access

## Limitations

### Thinking Models

Antigravity proxy cannot process "thinking blocks" from Claude's thinking models.

**Affected models:**
- `claude-sonnet-4-5-thinking`
- Any model with `-thinking` suffix

**Workaround:**
- Exit conversation before switching modes
- Use PAID mode for thinking models
- Or start fresh conversation in same mode

### Windows-Only

Currently Windows-only due to:
- PowerShell profile integration
- Path assumptions (`~/.claude/`)
- psmux dependency

**Future:** Mac/Linux support planned with shell detection

## Performance Optimizations

### Proxy Caching

Antigravity proxy caches:
- Google account tokens (until expiry)
- Quota information (5-minute cache)

### Lazy Loading

- Proxy only starts when needed
- Account detection deferred to first use
- Profile functions loaded on-demand

## Monitoring

### Health Checks

```powershell
# Check proxy
Test-NetConnection -ComputerName localhost -Port 8081

# Query API
Invoke-WebRequest http://localhost:8081/health

# View quotas
Invoke-RestMethod http://localhost:8081/account-limits?format=json
```

### Logging

**Antigravity Proxy:**
- Console output (when run manually)
- System logs (when run as service)

**Claude CLI:**
- Debug mode: `claude -d "api,hooks"`

## Related Documentation

- **[Setup Guide](SETUP.md)** - Installation details
- **[Usage Guide](USAGE.md)** - Daily workflows
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues
- **[Quick Reference](QUICK_REFERENCE.md)** - Command list

---

For implementation details, see source code at:
https://github.com/brandonkchow/claude-proxy-manager
