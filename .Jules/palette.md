## 2024-05-22 - [CLI Emoji Support in PowerShell]
**Learning:** PowerShell 5.1 (default on Windows) often defaults to a non-UTF8 encoding, causing emojis to render as garbage characters (mojibake).
**Action:** Always add `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` at the top of any PowerShell script that uses emojis or special characters in its output.
