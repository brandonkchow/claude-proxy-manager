# Unit tests for mode switching functionality

BeforeAll {
    # Setup test environment
    $script:TestRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:SwitchScript = Join-Path $TestRoot "scripts\switch-claude-mode.ps1"

    # Mock settings path for testing
    $script:TestSettingsDir = Join-Path $TestDrive "test-claude"
    New-Item -ItemType Directory -Path $script:TestSettingsDir -Force | Out-Null
    $script:TestSettingsPath = Join-Path $script:TestSettingsDir "settings.json"
}

Describe "Switch-Claude-Mode Script" {
    Context "When switching to PAID mode" {
        BeforeEach {
            # Create initial settings
            $initialSettings = @{
                env = @{
                    ANTHROPIC_BASE_URL = "http://localhost:8081"
                    ANTHROPIC_AUTH_TOKEN = "test"
                }
            } | ConvertTo-Json
            Set-Content -Path $script:TestSettingsPath -Value $initialSettings
        }

        It "Should clear proxy environment variables" {
            Mock Get-Content { return $initialSettings }
            Mock Set-Content {}
            Mock Remove-Item {}

            & $script:SwitchScript -Mode 'paid'

            Should -Invoke Remove-Item -ParameterFilter {
                $Path -match "ANTHROPIC_BASE_URL" -or $Path -match "ANTHROPIC_AUTH_TOKEN"
            }
        }

        It "Should create settings with empty env object" {
            & $script:SwitchScript -Mode 'paid'

            $settings = Get-Content $script:TestSettingsPath | ConvertFrom-Json
            $settings.env | Should -Not -BeNullOrEmpty
            $settings.env.PSObject.Properties.Count | Should -Be 0
        }

        It "Should backup existing settings before modification" {
            $backupPath = "$script:TestSettingsPath.backup"

            & $script:SwitchScript -Mode 'paid'

            Test-Path $backupPath | Should -Be $true
        }
    }

    Context "When switching to FREE mode" {
        BeforeEach {
            # Create paid mode settings
            $paidSettings = @{ env = @{} } | ConvertTo-Json
            Set-Content -Path $script:TestSettingsPath -Value $paidSettings
        }

        It "Should set proxy environment variables" {
            & $script:SwitchScript -Mode 'free'

            $settings = Get-Content $script:TestSettingsPath | ConvertFrom-Json
            $settings.env.ANTHROPIC_BASE_URL | Should -Be "http://localhost:8081"
            $settings.env.ANTHROPIC_AUTH_TOKEN | Should -Be "test"
        }

        It "Should set model configurations" {
            & $script:SwitchScript -Mode 'free'

            $settings = Get-Content $script:TestSettingsPath | ConvertFrom-Json
            $settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL | Should -Be "claude-sonnet-4-5"
            $settings.env.ANTHROPIC_DEFAULT_HAIKU_MODEL | Should -Be "gemini-3-flash"
            $settings.env.CLAUDE_CODE_SUBAGENT_MODEL | Should -Be "claude-sonnet-4-5"
        }

        It "Should warn if proxy is not running" {
            Mock Invoke-WebRequest { throw "Connection refused" }

            $output = & $script:SwitchScript -Mode 'free' 2>&1 | Out-String

            $output | Should -Match "Proxy server is NOT running"
        }
    }

    Context "When handling invalid input" {
        It "Should reject invalid mode parameter" {
            { & $script:SwitchScript -Mode 'invalid' } | Should -Throw
        }

        It "Should handle missing settings file gracefully" {
            Remove-Item $script:TestSettingsPath -Force -ErrorAction SilentlyContinue

            { & $script:SwitchScript -Mode 'paid' } | Should -Not -Throw
        }
    }
}

Describe "Settings Preservation" {
    Context "When switching modes" {
        It "Should preserve user-defined settings not related to proxy" {
            $customSettings = @{
                env = @{
                    ANTHROPIC_BASE_URL = "http://localhost:8081"
                    ANTHROPIC_AUTH_TOKEN = "test"
                    CUSTOM_SETTING = "preserve-me"
                }
                customConfig = @{
                    theme = "dark"
                }
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $script:TestSettingsPath -Value $customSettings

            & $script:SwitchScript -Mode 'paid'

            $settings = Get-Content $script:TestSettingsPath | ConvertFrom-Json
            $settings.customConfig.theme | Should -Be "dark"
        }
    }
}
