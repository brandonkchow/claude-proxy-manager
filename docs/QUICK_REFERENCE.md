# Claude Proxy Manager - Quick Reference Guide

## Help Command

Run `claude-help` anytime to see available commands!

```powershell
# Show all commands
claude-help

# Show detailed help for a specific command
claude-help dual-sessions
claude-help claude-free
claude-help check-usage
```

## Quick Command Reference

### Mode Switching
| Command | Description |
|---------|-------------|
| `claude-paid` | Switch to PAID Claude Code account |
| `claude-free` | Switch to FREE Antigravity proxy |
| `claude-mode` | Show current mode and configuration |

### Usage & Monitoring
| Command | Description |
|---------|-------------|
| `check-usage` | View quotas for all accounts |
| `start-proxy` | Manually start Antigravity proxy |

### Priority Management
| Command | Description |
|---------|-------------|
| `init-priority` | Initialize account priority configuration |
| `get-priority` | View current priority order |
| `set-priority` | Change account priority order |

### HappyCoder (Mobile Access)
| Command | Description |
|---------|-------------|
| `happy-free` | Start HappyCoder with Antigravity |
| `happy-paid` | Start HappyCoder with Claude Code |
| `dual-sessions` | **RECOMMENDED** - Start BOTH sessions for mobile |

## Dual-Sessions Usage

The `dual-sessions` command is the best way to use HappyCoder on mobile:

```powershell
# Basic usage (creates symlinks automatically)
dual-sessions

# Custom session name
dual-sessions -SessionName "WebDev"

# Disable symlinks (not recommended)
dual-sessions -NoSymlinks
```

### What dual-sessions does:
1. Creates symlinked directories:
   - `YourProject-FREE` (Antigravity)
   - `YourProject-PAID` (Claude Code)
2. Opens TWO PowerShell windows:
   - GREEN window = FREE mode
   - BLUE window = PAID mode
3. Each window displays a QR code for HappyCoder
4. Sessions appear as distinct entries in HappyCoder app

### First-time setup:
If symlinks fail to create, you may need to:
- **Option 1**: Enable Developer Mode (one-time)
  ```powershell
  # Run as Administrator:
  .\enable-symlinks.ps1
  ```
- **Option 2**: Use the elevated version
  ```powershell
  .\dual-sessions-elevated.ps1
  ```

After first-time setup, symlinks persist and no admin rights are needed!

## Common Workflows

### Daily Usage
```powershell
# Check which accounts have quota remaining
check-usage

# Switch to free mode for casual use
claude-free

# Switch to paid mode for important work
claude-paid
```

### Mobile Development
```powershell
# Start dual sessions for mobile access
dual-sessions

# Scan both QR codes with HappyCoder app
# Now you can switch between FREE and PAID on your phone!
```

### Remote Access (SSH/tmux)
```powershell
# Create tmux sessions
tmux new -s claude-free
# In that session:
happy-free

# Create another tmux session
tmux new -s claude-paid
# In that session:
happy-paid

# Detach with Ctrl+B, D
# Reattach anytime with: tmux attach -t claude-free
```

## Troubleshooting

### Proxy not running
```powershell
start-proxy
```

### Can't create symlinks
```powershell
# Enable Developer Mode (requires admin once):
.\enable-symlinks.ps1

# OR use elevated version:
.\dual-sessions-elevated.ps1
```

### Wrong mode active
```powershell
# Check current mode:
claude-mode

# Switch as needed:
claude-free
# or
claude-paid
```

### Forgot a command
```powershell
claude-help
# or
claude-help <command-name>
```

## Tips & Best Practices

1. **Use dual-sessions for mobile** - It's the easiest way to switch between FREE/PAID on your phone

2. **Check usage regularly** - Run `check-usage` to see quota remaining

3. **Set default priority** - Use `set-priority` to configure which accounts to use first

4. **Enable Developer Mode** - One-time setup makes symlinks work automatically

5. **Keep proxy running** - The proxy auto-starts, but you can manually start with `start-proxy`

## File Locations

- Settings: `~/.claude/settings.json`
- Priority config: `~/.claude/priority.json`
- Installed scripts: `~/.claude/claude-proxy-manager/`
- PowerShell profile: `$PROFILE`

## Links

- [GitHub Repository](https://github.com/brandonkchow/claude-proxy-manager)
- [Full Documentation](docs/)
- [Remote Access Guide](docs/REMOTE_ACCESS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

---

**Need help?** Run `claude-help` or `claude-help <command>`
