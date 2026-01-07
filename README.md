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

> [!CAUTION]
> **Thinking Model Incompatibility**
> 
> Do NOT switch between paid Claude Code and Antigravity proxy in the same conversation. Claude Code's thinking models (`-thinking` suffix) are incompatible with the Antigravity proxy.
> 
> **Why**: Antigravity proxy cannot process "thinking blocks" from Claude's extended thinking models. If you switch modes mid-conversation, you'll get API 400 errors.
> 
> **Solution**: Start a fresh conversation when switching modes:
> - Exit current conversation: `/exit` in Claude CLI
> - Switch modes: `claude-free` or `claude-paid`
> - Start new conversation: `claude`
> 
> **Best Practice**: Set your preferred mode as default priority to avoid switching.

## 💡 What is This?

Claude Proxy Manager lets you:

1. **Use multiple Claude accounts** - Switch between paid Claude Code and free Antigravity accounts
2. **Avoid thinking model conflicts** - Seamlessly move between conversations without API errors
3. **Maximize your quota** - Automatically use the right account at the right time
4. **Work remotely** - Perfect for SSH, tmux, and mobile workflows

## ✨ Features

- 🔄 **Flexible Priority System** - Configure which accounts to use first
- 🤖 **Auto-Start Proxy** - Proxy starts automatically when you need it
- 📊 **Unified Usage View** - See all account quotas in one place
- ⚡ **Smart Detection** - Auto-detects accounts and skips installed components
- 🎯 **Simple Commands** - `claude-free`, `claude-paid`, `check-usage`

## 📋 Prerequisites

- **Windows** (Mac/Linux support planned)
- **Node.js** 18+ ([Download](https://nodejs.org/))
- **Claude Code CLI** (installer can add this)
- At least one account:
  - Google account for Antigravity, OR
  - Paid Claude Code subscription

## 📖 Documentation

- [Setup Guide](docs/SETUP.md) - Detailed installation instructions
- [Usage Guide](docs/USAGE.md) - Daily workflows and commands
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Remote Access](docs/REMOTE_ACCESS.md) - SSH, tmux, Happy Coder
- [Architecture](docs/ARCHITECTURE.md) - How it works under the hood

## 🎯 Quick Commands

```powershell
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
Set-ClaudePriority
```

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
