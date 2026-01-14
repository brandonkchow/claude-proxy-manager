# Integration tests for update checker functionality

BeforeAll {
    $script:TestRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:ProfileSnippet = Join-Path $TestRoot "config\profile-snippet.ps1"

    # Source profile functions
    . $script:ProfileSnippet
}

Describe "Update-ClaudeProxyManager" {
    Context "When checking for updates" {
        BeforeEach {
            Mock Write-Host {}
        }

        It "Should check antigravity-claude-proxy version" {
            Mock npm {
                if ($args -contains "list") {
                    return "antigravity-claude-proxy@1.2.15"
                }
                if ($args -contains "view") {
                    return "1.2.16"
                }
            }

            Mock Invoke-RestMethod {
                return @{
                    tag_name = "v1.2.16"
                    body = "Bug fixes and improvements"
                }
            }

            Update-ClaudeProxyManager

            Should -Invoke npm -ParameterFilter {
                $args -contains "antigravity-claude-proxy"
            }
        }

        It "Should notify when update is available" {
            Mock npm {
                if ($args -contains "list") { return "antigravity-claude-proxy@1.2.15" }
                if ($args -contains "view") { return "1.2.16" }
            }

            Mock Invoke-RestMethod {
                return @{
                    tag_name = "v1.2.16"
                    body = "New features"
                }
            }

            Update-ClaudeProxyManager

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "UPDATE AVAILABLE" -and $ForegroundColor -eq "Yellow"
            }
        }

        It "Should confirm when up to date" {
            Mock npm {
                return "antigravity-claude-proxy@1.2.16"
            }

            Update-ClaudeProxyManager

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "up to date|latest" -and $ForegroundColor -match "Green"
            }
        }
    }

    Context "When fetching release notes" {
        BeforeEach {
            Mock npm {
                if ($args -contains "list") { return "antigravity-claude-proxy@1.2.15" }
                if ($args -contains "view") { return "1.2.16" }
            }
        }

        It "Should display release notes from GitHub" {
            Mock Invoke-RestMethod {
                return @{
                    tag_name = "v1.2.16"
                    body = @"
## Changes
- Feature: New capability
- Fix: Bug resolved
"@
                }
            }

            Update-ClaudeProxyManager

            Should -Invoke Invoke-RestMethod -ParameterFilter {
                $Uri -match "github.com.*releases"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "What's New|Changes"
            }
        }

        It "Should handle GitHub API failures gracefully" {
            Mock Invoke-RestMethod { throw "API rate limit exceeded" }

            { Update-ClaudeProxyManager } | Should -Not -Throw

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "Could not fetch|release notes"
            }
        }

        It "Should truncate long release notes" {
            Mock Invoke-RestMethod {
                $longBody = (1..50 | ForEach-Object { "Line $_" }) -join "`n"
                return @{
                    tag_name = "v1.2.16"
                    body = $longBody
                }
            }

            Update-ClaudeProxyManager

            # Should limit to reasonable number of lines (e.g., 10-15)
            Should -Invoke Write-Host -Times -LessThan 30
        }
    }

    Context "When providing update instructions" {
        BeforeEach {
            Mock npm {
                if ($args -contains "list") { return "antigravity-claude-proxy@1.2.15" }
                if ($args -contains "view") { return "1.2.16" }
            }

            Mock Invoke-RestMethod {
                return @{ tag_name = "v1.2.16"; body = "Updates" }
            }
        }

        It "Should show npm install command" {
            Update-ClaudeProxyManager

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "npm install -g antigravity-claude-proxy@latest"
            }
        }

        It "Should warn about daemon restart if running" {
            Mock Get-HappyDaemonStatus { return @{ Running = $true } }

            Update-ClaudeProxyManager

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "daemon.*restart|Restart.*daemon"
            }
        }
    }

    Context "When handling npm errors" {
        It "Should handle npm not found" {
            Mock npm { throw "npm: command not found" }

            { Update-ClaudeProxyManager } | Should -Not -Throw

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "npm.*not found|install npm" -and
                $ForegroundColor -eq "Red"
            }
        }

        It "Should handle package not installed" {
            Mock npm { return "" }

            { Update-ClaudeProxyManager } | Should -Not -Throw

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "not installed|install.*first"
            }
        }
    }
}

Describe "Version Comparison Logic" {
    Context "When comparing semantic versions" {
        It "Should detect major version updates" {
            $current = "1.2.15"
            $latest = "2.0.0"

            [version]$latest -gt [version]$current | Should -Be $true
        }

        It "Should detect minor version updates" {
            $current = "1.2.15"
            $latest = "1.3.0"

            [version]$latest -gt [version]$current | Should -Be $true
        }

        It "Should detect patch version updates" {
            $current = "1.2.15"
            $latest = "1.2.16"

            [version]$latest -gt [version]$current | Should -Be $true
        }

        It "Should handle version prefixes (v1.2.3)" {
            $versionString = "v1.2.16"
            $cleanVersion = $versionString.TrimStart('v')

            { [version]$cleanVersion } | Should -Not -Throw
        }
    }
}

Describe "Update Check Integration with Profile Load" {
    Context "When profile loads" {
        It "Should perform update check on profile load" {
            # This would be tested by sourcing profile and checking for update check call
            Set-ItResult -Skipped -Because "Requires full profile load testing"
        }

        It "Should respect update check frequency settings" {
            # Future enhancement: don't check on every load
            Set-ItResult -Skipped -Because "Feature not yet implemented"
        }
    }
}
