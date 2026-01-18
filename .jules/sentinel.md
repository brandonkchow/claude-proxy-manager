# Sentinel's Journal

## 2025-01-12 - [PowerShell Command Injection Vulnerability]
**Vulnerability:** Command Injection in `Start-DualSessions` via string interpolation in a Here-String that is passed to `powershell -Command`.
**Learning:** PowerShell Here-Strings expand variables, and if those variables contain single quotes (when the internal code uses single quotes), it breaks out of the string context. This allows executing arbitrary commands if the variable (like a directory name) is malicious.
**Prevention:** Always escape single quotes in variables (replace `'` with `''`) before interpolating them into a single-quoted string context in a generated script block. Even better, use parameters or encoded commands, but for `Start-Process -Command`, correct escaping is the most direct fix.

## 2026-01-13 - [Privilege Escalation in Elevation Script]
**Vulnerability:** Command Injection in `dual-sessions-elevated.ps1`. The script constructs an elevated PowerShell script block using string interpolation. If the working directory or derived paths contained single quotes, it would break out of the single-quoted string context, allowing arbitrary code execution with administrative privileges.
**Learning:** Even when interpolating into a temporary script file that is executed separately, if the content is generated via string interpolation of user-controlled variables (like file paths), those variables must be sanitized/escaped.
**Prevention:** Apply the same escaping strategy (`-replace "'", "''"`) for any variable interpolated into a PowerShell script block, especially when that block will be executed with higher privileges.

## 2025-05-23 - [Command Injection in Daemon Startup]
**Vulnerability:** Command Injection in `scripts/daemon-startup.ps1` via string interpolation of `$workDir` into a Here-String passed to `Start-Process powershell -Command`.
**Learning:** Similar to previous findings, user-controlled configuration (like `defaultWorkingDirectory` in `daemon-config.json`) can be manipulated (or just contain accidental single quotes) to break out of single-quoted strings in generated PowerShell commands.
**Prevention:** Always escape single quotes (`-replace "'", "''"`) when interpolating variables into single-quoted strings inside PowerShell script blocks or commands.

## 2025-06-15 - [Path Traversal and Partial Matching in PowerShell]
**Vulnerability:** In `scripts/switch-claude-mode.ps1`, the `SettingsPath` parameter was originally not validated, allowing arbitrary file overwrite. A naive fix using `StartsWith` for path validation introduced a partial matching vulnerability (e.g., `C:\Users\Bob` matches `C:\Users\Bobby`).
**Learning:** When validating paths using string prefix matching, you must ensure the prefix includes a directory separator to prevent partial directory name matches. Additionally, filesystem paths on Windows are case-insensitive, requiring `OrdinalIgnoreCase` comparison.
**Prevention:** Always resolve paths to absolute paths (`GetFullPath`), append a trailing directory separator to the allowed root path, and use case-insensitive comparison (`[System.StringComparison]::OrdinalIgnoreCase`) when validating path containment.
