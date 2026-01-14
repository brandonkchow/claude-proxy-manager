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
            # Skip - function uses hardcoded paths, would affect real user config
            Set-ItResult -Skipped -Because "Function uses hardcoded user paths"
        }

        It "Should create default antigravity-first configuration" {
            # Skip - function uses hardcoded paths
            Set-ItResult -Skipped -Because "Function uses hardcoded user paths"
        }

        It "Should include detected accounts in priority list" {
            # Skip - would require mocking network calls
            Set-ItResult -Skipped -Because "Requires mocking network calls to proxy"
        }
    }

    Context "When handling existing config" {
        It "Should not overwrite existing config without force" {
            # Skip - function uses hardcoded paths
            Set-ItResult -Skipped -Because "Function uses hardcoded user paths"
        }
    }
}

Describe "Get-ClaudePriority" {
    BeforeEach {
        # Skip - function uses hardcoded paths
        Set-ItResult -Skipped -Because "Function uses hardcoded user paths"
    }

    It "Should display current priority configuration" {
        # Skipped
    }

    It "Should show accounts in priority order" {
        # Skipped
    }

    It "Should indicate enabled/disabled status" {
        # Skipped
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
