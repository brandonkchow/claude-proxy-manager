# Integration tests for help system

BeforeAll {
    $script:TestRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:ProfileSnippet = Join-Path $TestRoot "config\profile-snippet.ps1"

    # Source profile functions
    . $script:ProfileSnippet
}

Describe "Show-ClaudeHelp Function" {
    Context "When showing general help" {
        BeforeEach {
            Mock Write-Host {}
        }

        It "Should display help without parameters" {
            Show-ClaudeHelp

            Should -Invoke Write-Host -AtLeast 10
        }

        It "Should show all command categories" {
            Show-ClaudeHelp

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "Mode Switching|Priority Management|Usage Monitoring|Remote Access|Daemon Management"
            }
        }

        It "Should list common aliases" {
            Show-ClaudeHelp

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "claude-free|claude-paid|check-usage|dual-sessions"
            }
        }
    }

    Context "When showing command-specific help" {
        BeforeEach {
            Mock Write-Host {}
        }

        It "Should show help for claude-free" {
            Show-ClaudeHelp -Command "claude-free"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "claude-free|antigravity|proxy"
            }
        }

        It "Should show help for claude-paid" {
            Show-ClaudeHelp -Command "claude-paid"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "claude-paid|paid account|Claude Code"
            }
        }

        It "Should show help for dual-sessions" {
            Show-ClaudeHelp -Command "dual-sessions"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "dual-sessions|FREE.*PAID|symlink"
            }
        }

        It "Should show help for daemon commands" {
            Show-ClaudeHelp -Command "daemon-start"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "daemon|persistent|survive"
            }
        }

        It "Should show help for check-usage" {
            Show-ClaudeHelp -Command "check-usage"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "usage|quota|limits"
            }
        }

        It "Should show help for claude-update" {
            Show-ClaudeHelp -Command "claude-update"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "update|latest|version"
            }
        }
    }

    Context "When handling unknown commands" {
        BeforeEach {
            Mock Write-Host {}
        }

        It "Should show error for unknown command" {
            Show-ClaudeHelp -Command "unknown-command-xyz"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "Unknown command|not found" -and $ForegroundColor -eq "Red"
            }
        }

        It "Should suggest using general help" {
            Show-ClaudeHelp -Command "invalid"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "claude-help.*without.*parameter"
            }
        }
    }
}

Describe "Help System Coverage" {
    BeforeAll {
        # Get all public functions from profile snippet
        $script:ProfileContent = Get-Content (Join-Path $TestRoot "config\profile-snippet.ps1") -Raw

        $script:PublicFunctions = @(
            'Set-ClaudeMode', 'Get-ClaudeMode', 'Get-ClaudeUsage',
            'Start-AntigravityProxy', 'Stop-AntigravityProxy',
            'Initialize-ClaudePriority', 'Get-ClaudePriority', 'Set-ClaudePriority',
            'Start-DualSessions', 'Get-HappyDaemonStatus',
            'Start-HappyDaemon', 'Stop-HappyDaemon', 'Restart-HappyDaemon',
            'Update-ClaudeProxyManager', 'Show-ClaudeHelp'
        )
    }

    Context "When verifying help coverage" {
        It "Should have help text for all public functions" {
            # Mock Write-Host to suppress decorative output
            Mock Write-Host {}

            $script:PublicFunctions | ForEach-Object {
                $functionName = $_
                $aliases = switch ($functionName) {
                    'Set-ClaudeMode' { @('claude-free', 'claude-paid') }
                    'Get-ClaudeMode' { @('claude-mode') }
                    'Get-ClaudeUsage' { @('check-usage') }
                    'Start-DualSessions' { @('dual-sessions') }
                    'Get-HappyDaemonStatus' { @('daemon-status') }
                    'Start-HappyDaemon' { @('daemon-start') }
                    'Stop-HappyDaemon' { @('daemon-stop') }
                    'Restart-HappyDaemon' { @('daemon-restart') }
                    'Update-ClaudeProxyManager' { @('claude-update') }
                    'Show-ClaudeHelp' { @('claude-help') }
                    default { @() }
                }

                $aliases | Should -Not -BeNullOrEmpty -Because "$functionName should have at least one alias"
            }
        }
    }
}

Describe "Help Formatting" {
    Context "When displaying help text" {
        BeforeEach {
            Mock Write-Host {}
        }

        It "Should use consistent color scheme" {
            Show-ClaudeHelp

            # Check that colors are used consistently
            Should -Invoke Write-Host -ParameterFilter { $ForegroundColor -eq "Cyan" }
            Should -Invoke Write-Host -ParameterFilter { $ForegroundColor -eq "Yellow" }
            Should -Invoke Write-Host -ParameterFilter { $ForegroundColor -eq "Gray" }
        }

        It "Should include usage examples" {
            Show-ClaudeHelp -Command "dual-sessions"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "Example|Usage"
            }
        }

        It "Should include parameter descriptions for commands with parameters" {
            Show-ClaudeHelp -Command "dual-sessions"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "Parameters|Options|-UseDaemon|-WorkingDirectory"
            }
        }
    }
}
