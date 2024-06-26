function WindowsFeatureBlock([string]$Comment, [string]$FeatureName) {
    Block "Windows Features > $Comment = On" {
        # https://github.com/PowerShell/PowerShell/issues/13866
        powershell -Command "Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -All -NoRestart"
    } {
        ((powershell -Command "(Get-WindowsOptionalFeature -Online -FeatureName $FeatureName).State -eq 'Enabled'") -eq "True")
    } -RequiresReboot
}

WindowsFeatureBlock ".NET Framework 3.5 (includes .NET 2.0 and 3.0)" NetFx3

WindowsFeatureBlock "Hyper-V" Microsoft-Hyper-V

    Block "Install WSL" {
        wsl --install -d Ubuntu
    } {
        (wsl -l) -replace "`0", "" | Select-String "Windows Subsystem for Linux Distributions:"
    } -RequiresReboot
