# Vulnerability Reproduction: Command Injection in Start-DualSessions

## Vulnerability Description
The function `Start-DualSessions` in `config/profile-snippet.ps1` constructs a PowerShell command string using a Here-String (`@"`). It interpolates variables like `$freeDir` (derived from the current working directory) directly into single-quoted strings within this command.

```powershell
    Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
Set-Location '$freeDir'
...
"@
```

If `$freeDir` contains a single quote (`'`), it terminates the single-quoted string `'$freeDir'` prematurely. An attacker can use this to inject arbitrary PowerShell commands.

## Proof of Concept (PoC)

If an attacker induces a user to download a directory with a malicious name and run `dual-sessions` inside it, code execution occurs.

**Malicious Directory Name:**
`Project'; Write-Host 'PWNED' -ForegroundColor Red; Start-Process calc; '`

**Resulting Command:**
When `Start-DualSessions` runs in this directory, `$freeDir` becomes the full path ending in the malicious name.
The generated command block becomes:

```powershell
Set-Location 'C:\Path\To\Project'; Write-Host 'PWNED' -ForegroundColor Red; Start-Process calc; ''
```

1. `Set-Location 'C:\Path\To\Project'` executes (changing to the first part of the path, or failing if path doesn't exist up to there, but likely the user is *in* that dir so the path is valid up to the injection).
2. `;` separates commands.
3. `Write-Host 'PWNED' -ForegroundColor Red` executes.
4. `Start-Process calc` executes (launching Calculator).
5. `''` is a harmless empty string string literal.

## Verification
To verify this locally (on a Windows machine with PowerShell):

1. Create a directory named `Test'; Write-Host 'INJECTED'; '`.
2. Enter that directory.
3. Source the profile snippet: `. .\config\profile-snippet.ps1`
4. Run `dual-sessions` (ensure `antigravity-claude-proxy` aliases are mocked or available, or the script will try to start them).
5. Observe the new window prints "INJECTED".

## Fix
Escape single quotes in the variables before interpolation. In PowerShell, a single quote inside a single-quoted string is escaped by doubling it (`''`).

```powershell
$safeFreeDir = $freeDir -replace "'", "''"
```
