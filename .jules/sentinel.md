# Sentinel's Journal

## 2025-01-12 - [PowerShell Command Injection Vulnerability]
**Vulnerability:** Command Injection in `Start-DualSessions` via string interpolation in a Here-String that is passed to `powershell -Command`.
**Learning:** PowerShell Here-Strings expand variables, and if those variables contain single quotes (when the internal code uses single quotes), it breaks out of the string context. This allows executing arbitrary commands if the variable (like a directory name) is malicious.
**Prevention:** Always escape single quotes in variables (replace `'` with `''`) before interpolating them into a single-quoted string context in a generated script block. Even better, use parameters or encoded commands, but for `Start-Process -Command`, correct escaping is the most direct fix.
