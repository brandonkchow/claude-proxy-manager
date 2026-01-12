# Fix for check-usage Display Issue

## Problem
The `check-usage` command shows empty quota values like:
```
- user1@gmail.com
  Claude:  / remaining
  Gemini:  / remaining
```

## Root Cause
The `priority.json` file wasn't properly initialized with Antigravity accounts. The file only contained:
```json
{
  "priority": [
    {
      "name": "Claude Code Paid",
      "type": "claude-code",
      "enabled": true
    }
  ]
}
```

Without Antigravity accounts in the priority config, the quota fetching code never runs.

## Solution (Automatic)
**The profile now auto-initializes priority configuration!**

When you reload your PowerShell profile (or restart PowerShell), it will:
1. Detect if `priority.json` is missing or incomplete
2. Check if Antigravity proxy is running with accounts
3. Automatically run account detection
4. Create/update priority configuration

You'll see:
```
[INFO] Antigravity accounts detected. Updating priority configuration...
Detecting available accounts...
  [OK] Found Antigravity account: user1@gmail.com
  [OK] Found Antigravity account: user2@gmail.com
  [OK] Claude Code authenticated
[OK] Priority configuration updated
```

## Manual Solution (if needed)
If auto-initialization doesn't work, run manually:

```powershell
init-priority
```

## After Fix
The output will show proper quotas:
```
[1] FREE Antigravity - user1@gmail.com
    Claude (Sonnet 4.5): 14% (Resets: 2026-01-10 6:24 AM)
    Gemini (Flash 3):    100% (Resets: 2026-01-10 7:22 AM)

[2] FREE Antigravity - user2@gmail.com
    Claude (Sonnet 4.5): 35% (Resets: 2026-01-10 6:57 AM)
    Gemini (Flash 3):    100% (Resets: 2026-01-10 7:22 AM)

[3] PAID Claude Code Account
    Status: Available (Switch with: claude-paid)
```

## Implementation Details
The auto-initialization happens when the profile loads:
- **Missing priority.json**: Immediately runs `Initialize-ClaudePriority`
- **Incomplete priority.json**: Checks if Antigravity accounts are detected but not configured
- **Silent fallback**: If proxy isn't running or detection fails, falls back gracefully

Users no longer need to remember to run `init-priority` - it happens automatically!

