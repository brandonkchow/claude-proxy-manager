# Claude Proxy Manager

> **Seamlessly manage Claude Code CLI with Antigravity proxy and paid accounts**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/powershell/)

## 🚀 Quick Start

```powershell
iwr -useb https://raw.githubusercontent.com/brandonkchow/claude-proxy-manager/main/scripts/install.ps1 | iex
```

That's it! The installer will:
- ✅ Check prerequisites
- ✅ Auto-install missing components (with your permission)
- ✅ Detect your existing accounts
- ✅ Configure priority order
- ✅ Set up auto-start
- ✅ Add PowerShell functions
- ✅ **Optional**: Install SSH, tmux, and HappyCoder for remote access

## 💡 What is This?

Claude Proxy Manager lets you:

1. **Use multiple Claude accounts** - Switch between paid Claude Code and free Antigravity accounts
2. **Maximize your quota** - Automatically use the right account at the right time
3. **Work remotely** - Perfect for SSH, tmux, and mobile workflows

## ✨ Features

- 🔄 **Flexible Priority System** - Configure which accounts to use first
- 🤖 **Auto-Start Proxy** - Proxy starts automatically when you need it
- ⚡ **Auto-Initialize** - Priority config auto-detects accounts on first load
- 📊 **Unified Usage View** - See all account quotas in one place
- 🎯 **Smart Detection** - Auto-detects accounts and skips installed components
- 💡 **Built-in Help** - Run `claude-help` anytime for command reference
- 🎨 **Simple Commands** - `claude-free`, `claude-paid`, `check-usage`, `dual-sessions`

## 📋 Prerequisites

- **Windows** (Mac/Linux support planned)
- **Node.js** 18+ ([Download](https://nodejs.org/))
- **Claude Code CLI** (installer can add this)
- At least one account:
  - Google account for Antigravity, OR
  - Paid Claude Code subscription

## 📖 Documentation

- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Command cheat sheet and common workflows ⭐
- [Setup Guide](docs/SETUP.md) - Detailed installation instructions
- [Usage Guide](docs/USAGE.md) - Daily workflows and commands
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Remote Access](docs/REMOTE_ACCESS.md) - SSH, tmux, Happy Coder
- [Architecture](docs/ARCHITECTURE.md) - How it works under the hood

**Built-in help:** Run `claude-help` anytime in PowerShell!

## 🎯 Quick Commands

```powershell
# Get help anytime!
claude-help                      # Show all commands
claude-help dual-sessions        # Detailed help for specific command

# Check current mode and quotas
check-usage

# Switch to free Antigravity accounts
claude-free

# Switch to paid Claude Code account
claude-paid

# Show current configuration
claude-mode

# Start proxy manually
start-proxy

# Configure priority order
set-priority

# HappyCoder mobile access
happy-free          # Start HappyCoder with Antigravity
happy-paid          # Start HappyCoder with Claude Code
dual-sessions       # Start BOTH sessions for easy mobile switching (RECOMMENDED)
```

### 📱 Dual Sessions for HappyCoder (Mobile Access)

The `dual-sessions` command is the **best way** to use HappyCoder on mobile:

```powershell
# Simply run:
dual-sessions
```

**What it does:**
1. Creates symlinked directories (`myproject-FREE` and `myproject-PAID`)
2. Starts the Antigravity proxy if needed
3. Opens two color-coded PowerShell windows:
   - 🟢 **Green** = FREE mode (Antigravity)
   - 🔵 **Blue** = PAID mode (Claude Code)
4. Displays QR codes for both sessions

**In your HappyCoder mobile app, you'll see:**
- 🟢 `myproject-FREE` ← Free Antigravity session
- 🔵 `myproject-PAID` ← Paid Claude Code session

**Benefits:**
- Instantly switch between FREE and PAID on your phone
- No need to stop/restart sessions
- Clear visual identification in both desktop and mobile
- Works great with tmux/psmux for persistent sessions

**Advanced usage:**
```powershell
dual-sessions -SessionName "MyWork"  # Custom session name
dual-sessions -NoSymlinks            # Disable symlinks (shows warning)
```

See [Remote Access Guide](docs/REMOTE_ACCESS.md) for SSH and tmux setup.

## 🤝 Contributing

Contributions welcome! Please read our [Contributing Guide](CONTRIBUTING.md) first.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [antigravity-claude-proxy](https://github.com/badri-s2001/antigravity-claude-proxy) - The proxy that makes this possible
- [Claude Code CLI](https://docs.anthropic.com/claude/docs) - Anthropic's official CLI

## 📞 Support

- 🐛 [Report a Bug](https://github.com/brandonkchow/claude-proxy-manager/issues)
- 💡 [Request a Feature](https://github.com/brandonkchow/claude-proxy-manager/issues)
- 💬 [Discussions](https://github.com/brandonkchow/claude-proxy-manager/discussions)

---

**Made with ❤️ for developers who want seamless Claude access**
