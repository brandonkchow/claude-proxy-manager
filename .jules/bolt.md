# Bolt's Journal

## 2024-05-22 - PowerShell JSON Performance
**Learning:** PowerShell's `ConvertFrom-Json` and `ConvertTo-Json` can be slow, especially when reading files from disk repeatedly.
**Action:** When possible, cache the parsed JSON object in a session variable instead of reading and parsing the file every time a function is called, especially if the file changes infrequently.

## 2024-05-22 - Process Startup Cost
**Learning:** Checking for external process versions or existence (like `claude --version`) can be slow if done frequently.
**Action:** Cache the result of these checks in session variables or global variables so they are only performed once per session.

## 2024-05-22 - Optimize Profile Loading
**Learning:** The `profile-snippet.ps1` runs on every PowerShell startup. It performs network requests (to `localhost:8081` for priority check) and file reads (`Get-Content`, `ConvertFrom-Json`).
**Action:** Minimize work done during profile loading. Async checks or caching can improve startup time.

## 2025-05-22 - Network Port Checks
**Learning:** `Test-NetConnection` is Windows-specific and slow (often pings first). It is not available on standard Linux PowerShell Core.
**Action:** Replace `Test-NetConnection` with `System.Net.Sockets.TcpClient` for fast (ms vs sec), cross-platform port checking.
