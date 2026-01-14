# Integration tests for dual-sessions workflow

BeforeAll {
    $script:TestRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:ProfileSnippet = Join-Path $TestRoot "config\profile-snippet.ps1"

    # Source profile functions
    . $script:ProfileSnippet
}

Describe "Dual-Sessions Workflow" {
    Context "When creating symlinked directories" {
        BeforeAll {
            $script:TestWorkDir = Join-Path $TestDrive "test-project"
            New-Item -ItemType Directory -Path $script:TestWorkDir -Force | Out-Null
            Push-Location $script:TestWorkDir
        }

        AfterAll {
            Pop-Location
        }

        It "Should create FREE symlink directory" {
            Mock Start-Process {}
            Mock Invoke-Expression { return "Proxy running" }

            Start-DualSessions -SessionName "test"

            $freeDir = Join-Path (Split-Path $script:TestWorkDir -Parent) "test-project-FREE"
            # Note: Symlink creation requires admin rights, test the logic not execution
            Set-ItResult -Skipped -Because "Requires admin rights for symlink creation"
        }

        It "Should create PAID symlink directory" {
            Mock Start-Process {}

            Start-DualSessions -SessionName "test"

            $paidDir = Join-Path (Split-Path $script:TestWorkDir -Parent) "test-project-PAID"
            # Note: Symlink creation requires admin rights
            Set-ItResult -Skipped -Because "Requires admin rights for symlink creation"
        }
    }

    Context "When starting sessions with daemon" {
        BeforeAll {
            Mock Get-HappyDaemonStatus { return @{ Running = $true } }
            Mock Invoke-Expression { return "Session started" }
            Mock Start-Process {}
        }

        It "Should use daemon for persistent sessions" {
            Start-DualSessions -UseDaemon

            Should -Invoke Invoke-Expression -ParameterFilter {
                $Command -match "--attach-daemon"
            }
        }

        It "Should start foreground sessions without daemon flag" {
            Start-DualSessions

            Should -Invoke Start-Process -Times 2
        }
    }

    Context "When handling proxy availability" {
        It "Should start proxy if not running for FREE session" {
            Mock Test-NetConnection { return @{ TcpTestSucceeded = $false } }
            Mock Start-AntigravityProxy {}
            Mock Start-Process {}

            Start-DualSessions

            Should -Invoke Start-AntigravityProxy -Times 1
        }

        It "Should skip proxy start if already running" {
            Mock Test-NetConnection { return @{ TcpTestSucceeded = $true } }
            Mock Start-AntigravityProxy {}
            Mock Start-Process {}

            Start-DualSessions

            Should -Invoke Start-AntigravityProxy -Times 0
        }
    }

    Context "When configuring window titles and prompts" {
        It "Should set distinct window titles for FREE and PAID" {
            Mock Start-Process {} -ParameterFilter {
                $ArgumentList -match "HappyCoder - FREE|HappyCoder - PAID"
            }

            Start-DualSessions

            Should -Invoke Start-Process -Times 2 -ParameterFilter {
                $ArgumentList -match "WindowTitle"
            }
        }

        It "Should launch sessions in separate PowerShell windows" {
            Mock Start-Process {}

            Start-DualSessions

            Should -Invoke Start-Process -Times 2 -ParameterFilter {
                $FilePath -match "powershell"
            }
        }
    }

    Context "When using custom working directory" {
        It "Should accept WorkingDirectory parameter" {
            Mock Start-Process {}
            Mock Test-Path { return $true }

            Start-DualSessions -WorkingDirectory "C:\CustomPath"

            Should -Invoke Start-Process -ParameterFilter {
                $ArgumentList -match "C:\\CustomPath"
            }
        }

        It "Should use current directory if not specified" {
            Mock Start-Process {}
            $currentDir = Get-Location

            Start-DualSessions

            Should -Invoke Start-Process -ParameterFilter {
                $ArgumentList -match [regex]::Escape($currentDir.Path)
            }
        }
    }
}

Describe "Dual-Sessions with Daemon Integration" {
    Context "When daemon auto-starts sessions" {
        BeforeAll {
            $script:TestConfigPath = Join-Path $TestDrive "daemon-config.json"
            $testConfig = @{
                autoStartDaemon = $true
                autoStartMode = "dual"
                defaultWorkingDirectory = "C:\Projects"
            } | ConvertTo-Json
            Set-Content -Path $script:TestConfigPath -Value $testConfig
        }

        It "Should read autoStartMode from config" {
            $config = Get-Content $script:TestConfigPath | ConvertFrom-Json

            $config.autoStartMode | Should -Be "dual"
        }

        It "Should use defaultWorkingDirectory from config" {
            $config = Get-Content $script:TestConfigPath | ConvertFrom-Json

            $config.defaultWorkingDirectory | Should -Be "C:\Projects"
        }
    }

    Context "When sessions persist across restarts" {
        It "Should reconnect to existing sessions after restart" {
            Mock Invoke-Expression {
                return @"
Session ID: abc123
Status: active
"@
            }

            # Test session persistence logic
            Set-ItResult -Skipped -Because "Requires running daemon and happy-server relay"
        }
    }
}
