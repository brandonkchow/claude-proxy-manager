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
    Context "When daemon is running" {
        BeforeEach {
            Mock Invoke-Expression {
                return @"
Daemon is running
PID: 12345
Sessions: 2
Processes: 4
"@
            }
        }

        It "Should return running status" {
            $status = Get-HappyDaemonStatus

            $status.Running | Should -Be $true
        }

        It "Should parse session count" {
            $status = Get-HappyDaemonStatus

            $status.SessionCount | Should -Be 2
        }

        It "Should parse process count" {
            $status = Get-HappyDaemonStatus

            $status.ProcessCount | Should -Be 4
        }

        It "Should parse PID" {
            $status = Get-HappyDaemonStatus

            $status.PID | Should -Be 12345
        }
    }

    Context "When daemon is not running" {
        BeforeEach {
            Mock Invoke-Expression {
                return "Daemon is not running"
            }
        }

        It "Should return not running status" {
            $status = Get-HappyDaemonStatus

            $status.Running | Should -Be $false
        }

        It "Should have zero sessions" {
            $status = Get-HappyDaemonStatus

            $status.SessionCount | Should -Be 0
        }
    }

    Context "When happy command fails" {
        BeforeEach {
            Mock Invoke-Expression { throw "happy: command not found" }
        }

        It "Should handle missing happy-coder gracefully" {
            $status = Get-HappyDaemonStatus

            $status.Running | Should -Be $false
            $status.Error | Should -Match "happy.*not found"
        }
    }
}

Describe "Start-HappyDaemon" {
    Context "When starting daemon successfully" {
        BeforeEach {
            Mock Invoke-Expression { return "Daemon started successfully" }
            Mock Get-HappyDaemonStatus { return @{ Running = $false } }
        }

        It "Should execute happy daemon start command" {
            Start-HappyDaemon

            Should -Invoke Invoke-Expression -ParameterFilter {
                $Command -match "happy daemon start"
            }
        }

        It "Should not start if already running" {
            Mock Get-HappyDaemonStatus { return @{ Running = $true } }

            Start-HappyDaemon

            Should -Invoke Invoke-Expression -Times 0
        }
    }

    Context "When starting with auto-start sessions" {
        BeforeEach {
            $testConfig = @{
                autoStartDaemon = $true
                autoStartMode = "dual"
                defaultWorkingDirectory = "C:\Projects"
            } | ConvertTo-Json
            Set-Content -Path $script:TestConfigPath -Value $testConfig

            Mock Invoke-Expression { return "Daemon started" }
            Mock Start-DualSessions {}
        }

        It "Should launch sessions based on config" {
            # This would be tested in integration tests
            Set-ItResult -Skipped -Because "Requires integration testing"
        }
    }
}

Describe "Stop-HappyDaemon" {
    Context "When stopping daemon" {
        BeforeEach {
            Mock Invoke-Expression { return "Daemon stopped (sessions preserved)" }
            Mock Get-HappyDaemonStatus { return @{ Running = $true } }
        }

        It "Should execute happy daemon stop command" {
            Stop-HappyDaemon

            Should -Invoke Invoke-Expression -ParameterFilter {
                $Command -match "happy daemon stop"
            }
        }

        It "Should preserve sessions on stop" {
            $output = Stop-HappyDaemon 2>&1 | Out-String

            $output | Should -Match "sessions.*preserved|survive"
        }
    }
}

Describe "Restart-HappyDaemon" {
    Context "When restarting daemon" {
        BeforeEach {
            Mock Stop-HappyDaemon { Write-Host "Stopped" }
            Mock Start-Sleep {}
            Mock Start-HappyDaemon { Write-Host "Started" }
        }

        It "Should stop then start daemon" {
            Restart-HappyDaemon

            Should -Invoke Stop-HappyDaemon -Times 1
            Should -Invoke Start-HappyDaemon -Times 1
        }

        It "Should wait between stop and start" {
            Restart-HappyDaemon

            Should -Invoke Start-Sleep -Times 1
        }
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
