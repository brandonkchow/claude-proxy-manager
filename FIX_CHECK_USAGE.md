# Fix for check-usage Display Issue

## Problem
The `check-usage` command shows empty quota values like:
```
- anisenseiko@gmail.comClaude:  / remaining
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

## Solution
Run the initialization command to auto-detect all accounts:

```powershell
init-priority
```

This will:
1. Detect all Antigravity/Google accounts from the proxy
2. Detect Claude Code authentication
3. Create proper priority configuration
4. Enable quota display in `check-usage`

## After Fix
The output will show proper quotas:
```
[1] PAID Claude Code Account
    Status: Available (Switch with: claude-paid)

[2] FREE Antigravity - anisenseiko@gmail.com
    Claude (Sonnet 4.5): 14% (Resets: 2026-01-10 6:24 AM)
    Gemini (Flash 3):    100% (Resets: 2026-01-10 7:19 AM)

[3] FREE Antigravity - beastbzn@gmail.com
    Claude (Sonnet 4.5): 45% (Resets: 2026-01-10 6:57 AM)
    Gemini (Flash 3):    100% (Resets: 2026-01-10 7:19 AM)
```

## Code Improvement
Updated the fallback message in `check-usage` to be more helpful when priority config is missing or incomplete.
