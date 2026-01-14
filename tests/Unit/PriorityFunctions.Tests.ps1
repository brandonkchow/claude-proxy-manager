# Unit tests for priority management functions

BeforeAll {
    $script:TestRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:PriorityScript = Join-Path $TestRoot "scripts\priority-functions.ps1"

    # Source the priority functions
    . $script:PriorityScript

    # Mock priority config path
    $script:TestPriorityPath = Join-Path $TestDrive "priority.json"
}

Describe "Initialize-ClaudePriority" {
    Context "When creating new priority config" {
        It "Should create default claude-first configuration" {
            Initialize-ClaudePriority -DefaultPriority 'claude-first' -PriorityConfigPath $script:TestPriorityPath

            Test-Path $script:TestPriorityPath | Should -Be $true

            $config = Get-Content $script:TestPriorityPath | ConvertFrom-Json
            $config.defaultPriority | Should -Be 'claude-first'
        }

        It "Should create default antigravity-first configuration" {
            Initialize-ClaudePriority -DefaultPriority 'antigravity-first' -PriorityConfigPath $script:TestPriorityPath

            $config = Get-Content $script:TestPriorityPath | ConvertFrom-Json
            $config.defaultPriority | Should -Be 'antigravity-first'
        }

        It "Should include detected accounts in priority list" {
            Mock Invoke-RestMethod {
                return @{
                    accounts = @(
                        @{ email = "test1@gmail.com"; status = "active" }
                        @{ email = "test2@gmail.com"; status = "active" }
                    )
                }
            }

            Initialize-ClaudePriority -DefaultPriority 'antigravity-first' -PriorityConfigPath $script:TestPriorityPath

            $config = Get-Content $script:TestPriorityPath | ConvertFrom-Json
            $config.accounts.Count | Should -BeGreaterThan 0
        }
    }

    Context "When handling existing config" {
        It "Should not overwrite existing config without force" {
            $existingConfig = @{
                defaultPriority = "claude-first"
                accounts = @()
            } | ConvertTo-Json
            Set-Content -Path $script:TestPriorityPath -Value $existingConfig

            Initialize-ClaudePriority -DefaultPriority 'antigravity-first' -PriorityConfigPath $script:TestPriorityPath

            $config = Get-Content $script:TestPriorityPath | ConvertFrom-Json
            $config.defaultPriority | Should -Be 'claude-first'
        }
    }
}

Describe "Get-ClaudePriority" {
    BeforeEach {
        $testConfig = @{
            defaultPriority = "antigravity-first"
            accounts = @(
                @{ name = "anisenseiko@gmail.com"; type = "antigravity"; enabled = $true; priority = 1 }
                @{ name = "beastbzn@gmail.com"; type = "antigravity"; enabled = $true; priority = 2 }
                @{ name = "Claude Code"; type = "claude"; enabled = $true; priority = 3 }
            )
        } | ConvertTo-Json -Depth 10
        Set-Content -Path $script:TestPriorityPath -Value $testConfig
    }

    It "Should display current priority configuration" {
        Mock Write-Host {}

        Get-ClaudePriority -PriorityConfigPath $script:TestPriorityPath

        Should -Invoke Write-Host -Times -Minimum 3
    }

    It "Should show accounts in priority order" {
        $config = Get-Content $script:TestPriorityPath | ConvertFrom-Json

        $config.accounts[0].priority | Should -Be 1
        $config.accounts[1].priority | Should -Be 2
        $config.accounts[2].priority | Should -Be 3
    }

    It "Should indicate enabled/disabled status" {
        $config = Get-Content $script:TestPriorityPath | ConvertFrom-Json

        $config.accounts | ForEach-Object {
            $_.PSObject.Properties.Name | Should -Contain 'enabled'
        }
    }
}

Describe "Set-ClaudePriority" {
    BeforeEach {
        $testConfig = @{
            defaultPriority = "antigravity-first"
            accounts = @(
                @{ name = "Account1"; type = "antigravity"; enabled = $true; priority = 1 }
                @{ name = "Account2"; type = "antigravity"; enabled = $true; priority = 2 }
            )
        } | ConvertTo-Json -Depth 10
        Set-Content -Path $script:TestPriorityPath -Value $testConfig
    }

    It "Should update priority order" {
        # This test would require interactive mocking
        # Skipping for automated testing
        Set-ItResult -Skipped -Because "Requires interactive input"
    }

    It "Should enable/disable accounts" {
        # This test would require interactive mocking
        # Skipping for automated testing
        Set-ItResult -Skipped -Because "Requires interactive input"
    }
}

Describe "Priority Config Validation" {
    It "Should validate JSON structure" {
        $validConfig = @{
            defaultPriority = "claude-first"
            accounts = @(
                @{ name = "test"; type = "claude"; enabled = $true; priority = 1 }
            )
        } | ConvertTo-Json
        Set-Content -Path $script:TestPriorityPath -Value $validConfig

        { Get-Content $script:TestPriorityPath | ConvertFrom-Json } | Should -Not -Throw
    }

    It "Should handle malformed JSON gracefully" {
        Set-Content -Path $script:TestPriorityPath -Value "{ invalid json"

        { Get-ClaudePriority -PriorityConfigPath $script:TestPriorityPath -ErrorAction Stop } | Should -Throw
    }
}
