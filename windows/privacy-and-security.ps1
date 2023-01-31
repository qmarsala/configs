# FirstRunBlock "Privacy & security > Device encryption > BitLocker drive encryption > Back up your recovery key" {
#     $recoveryKey = (Get-BitLockerVolume).KeyProtector | ? { $_.KeyProtectorType -eq "RecoveryPassword" }
#     Add-Content "$OneDrive\BitLocker Recovery Key ($env:ComputerName) $($recoveryKey.KeyProtectorId.Trim('{', '}')).txt" $recoveryKey.RecoveryPassword
# }
Block "Privacy & security > For developers > Change settings to allow remote connections to this computer > Show settings > Allow Remote Assistance connections to this computer = Off" {
    Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name fAllowToGetHelp -Value 0
    Disable-NetFirewallRule -DisplayGroup "Remote Assistance"
}
Block "Turn off web search in start menu" {
    Set-RegistryValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name DisableSearchBoxSuggestions -Value 1
}
