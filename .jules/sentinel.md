# Sentinel's Journal

## 2025-01-12 - [PowerShell Command Injection Vulnerability]
**Vulnerability:** Command Injection in `Start-DualSessions` via string interpolation in a Here-String that is passed to `powershell -Command`.
**Learning:** PowerShell Here-Strings expand variables, and if those variables contain single quotes (when the internal code uses single quotes), it breaks out of the string context. This allows executing arbitrary commands if the variable (like a directory name) is malicious.
**Prevention:** Always escape single quotes in variables (replace `'` with `''`) before interpolating them into a single-quoted string context in a generated script block. Even better, use parameters or encoded commands, but for `Start-Process -Command`, correct escaping is the most direct fix.

## 2026-01-13 - [Privilege Escalation in Elevation Script]
**Vulnerability:** Command Injection in `dual-sessions-elevated.ps1`. The script constructs an elevated PowerShell script block using string interpolation. If the working directory or derived paths contained single quotes, it would break out of the single-quoted string context, allowing arbitrary code execution with administrative privileges.
**Learning:** Even when interpolating into a temporary script file that is executed separately, if the content is generated via string interpolation of user-controlled variables (like file paths), those variables must be sanitized/escaped.
**Prevention:** Apply the same escaping strategy (`-replace "'", "''"`) for any variable interpolated into a PowerShell script block, especially when that block will be executed with higher privileges.

## 2026-01-14 - [Insecure Default Binding in Dependency]
**Vulnerability:** `antigravity-claude-proxy` binds to all interfaces (::) by default, exposing the proxy to the local network. It does not currently support a configuration to restrict this to localhost.
**Learning:** External dependencies may have insecure defaults that cannot be easily patched. Defense-in-depth measures (firewall rules, environment variables for future support) are necessary when upstream fixes are not immediately available.
**Prevention:** In the absence of upstream support, we can use firewall rules to block external access to the port. Defense-in-depth: set `HOST` environment variable in case support is added.
