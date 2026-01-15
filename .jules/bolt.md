## 2024-05-22 - Optimize Shell Startup: Command Existence Checks
**Learning:** In PowerShell, checking if a tool is installed by running it (e.g., `tool --version`) can be significantly slower than using `Get-Command tool` if the tool is a heavy runtime (like Node.js). This is especially critical for profile scripts that run on every shell load.
**Action:** Use `if (Get-Command name -ErrorAction SilentlyContinue)` to check existence instead of running the tool. Only run the tool if you actually need the output.

## 2024-05-22 - Optimize Shell Startup: Lightweight Port Checks
**Learning:** `Invoke-WebRequest` is heavy for simple "is the server running?" checks during startup, especially with its default timeout behavior. A lightweight TCP socket check (`System.Net.Sockets.TcpClient`) is orders of magnitude faster and allows for tighter timeouts (e.g., 200ms).
**Action:** Prefer `Test-PortOpen` (custom helper using TcpClient) over `Invoke-WebRequest` or `Test-NetConnection` for rapid status indicators in interactive scripts.
