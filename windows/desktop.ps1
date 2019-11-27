Block "Desktop > View > Small icons" {
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop" -Name IconSize -Value 32; Stop-Process -ProcessName explorer
}
Block "Clean up items on desktop" {
    Remove-Item "$env:UserProfile\Desktop\Microsoft Edge.lnk"
}
Block "Taskbar > Search = Hidden" {
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name SearchboxTaskbarMode -Value 0
}
Block "Taskbar > Show Cortana button = Off" {
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowCortanaButton -Value 0
}
Block "Taskbar > Show Windows Ink Workspace button = Off" {
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\PenWorkspace" -Name PenWorkspaceButtonDesiredVisibility -Value 0
}