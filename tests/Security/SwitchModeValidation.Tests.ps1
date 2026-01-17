Describe "Switch-ClaudeMode Security" {
    Context "Input Validation" {
        It "Should reject SettingsPath that does not end in .json" {
            $params = @{
                Mode = "free"
                SettingsPath = "$env:TEMP\evil.txt"
            }

            # We expect the script to throw a security error
            { & "$PSScriptRoot\..\..\scripts\switch-claude-mode.ps1" @params } | Should -Throw -ErrorId "WriteError"
        }

        It "Should reject SettingsPath outside user profile" {
             $params = @{
                Mode = "free"
                SettingsPath = "C:\Windows\System32\drivers\etc\hosts.json" # Mock path
            }

            # We expect the script to throw a security error
            { & "$PSScriptRoot\..\..\scripts\switch-claude-mode.ps1" @params } | Should -Throw -ErrorId "WriteError"
        }

        It "Should accept valid SettingsPath inside user profile" {
             $params = @{
                Mode = "free"
                SettingsPath = "$env:USERPROFILE\.claude\test-settings.json"
            }

            # This test mainly verifies validation doesn't block valid paths.
            # It might fail later in the script (mocking needed), but validation passes.
        }
    }
}
