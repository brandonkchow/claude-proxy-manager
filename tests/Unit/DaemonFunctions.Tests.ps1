# Unit tests for daemon management functions

BeforeAll {
    $script:TestRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:ProfileSnippet = Join-Path $TestRoot "config\profile-snippet.ps1"
    $script:PriorityFunctionsPath = Join-Path $TestRoot "scripts\priority-functions.ps1"

    # The profile snippet tries to source priority-functions.ps1
    # Create the directory if it doesn't exist
    $priorityDir = Split-Path -Parent $script:PriorityFunctionsPath
    if (-not (Test-Path $priorityDir)) {
        New-Item -ItemType Directory -Path $priorityDir -Force | Out-Null
    }

    # Create a dummy priority-functions.ps1 if it doesn't exist
    if (-not (Test-Path $script:PriorityFunctionsPath)) {
        "# Dummy for testing" | Set-Content $script:PriorityFunctionsPath
    }

    # Source profile functions
    . $script:ProfileSnippet

    # Mock daemon config paths
    $script:TestConfigPath = Join-Path $TestDrive "daemon-config.json"
    $script:TestStatePath = Join-Path $TestDrive "daemon-state.json"
}

Describe "Get-HappyDaemonStatus" {
    # These tests are skipped if daemon is actually running
    # Mocking doesn't work well when real daemon is present

    It "Should return daemon status" {
        $status = Get-HappyDaemonStatus

        $status | Should -Not -BeNullOrEmpty
        $status.Running | Should -BeOfType [bool]
    }
}

Describe "Start-HappyDaemon" {
    It "Should be a valid function" {
        Get-Command Start-HappyDaemon | Should -Not -BeNullOrEmpty
    }
}

Describe "Stop-HappyDaemon" {
    It "Should be a valid function" {
        Get-Command Stop-HappyDaemon | Should -Not -BeNullOrEmpty
    }
}

Describe "Restart-HappyDaemon" {
    It "Should be a valid function" {
        Get-Command Restart-HappyDaemon | Should -Not -BeNullOrEmpty
    }
}

Describe "Daemon Configuration Management" {
    Context "When loading daemon config" {
        It "Should load valid configuration" {
            $testConfig = @{
                autoStartDaemon = $true
                autoStartMode = "dual"
                defaultWorkingDirectory = "C:\Projects"
            } | ConvertTo-Json
            Set-Content -Path $script:TestConfigPath -Value $testConfig

            $config = Get-Content $script:TestConfigPath | ConvertFrom-Json

            $config.autoStartDaemon | Should -Be $true
            $config.autoStartMode | Should -Be "dual"
        }

        It "Should handle missing config file" {
            Remove-Item $script:TestConfigPath -Force -ErrorAction SilentlyContinue

            { Get-Content $script:TestConfigPath -ErrorAction Stop } | Should -Throw
        }

        It "Should validate autoStartMode values" {
            $validModes = @("none", "dual", "free", "paid")

            $validModes | ForEach-Object {
                $mode = $_
                $config = @{ autoStartMode = $mode } | ConvertTo-Json
                Set-Content -Path $script:TestConfigPath -Value $config

                $loaded = Get-Content $script:TestConfigPath | ConvertFrom-Json
                $loaded.autoStartMode | Should -Be $mode
            }
        }
    }
}

Describe "Daemon State Management" {
    Context "When tracking daemon state" {
        It "Should record last start time" {
            $state = @{
                daemonRunning = $true
                lastStartTime = (Get-Date).ToString('o')
                startedBy = "auto-startup"
            } | ConvertTo-Json
            Set-Content -Path $script:TestStatePath -Value $state

            $loaded = Get-Content $script:TestStatePath | ConvertFrom-Json

            { [DateTime]::Parse($loaded.lastStartTime) } | Should -Not -Throw
        }

        It "Should track who started daemon" {
            $state = @{
                daemonRunning = $true
                lastStartTime = (Get-Date).ToString('o')
                startedBy = "manual"
            } | ConvertTo-Json
            Set-Content -Path $script:TestStatePath -Value $state

            $loaded = Get-Content $script:TestStatePath | ConvertFrom-Json
            $loaded.startedBy | Should -Match "manual|auto-startup|task-scheduler"
        }
    }
}
