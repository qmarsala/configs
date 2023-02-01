InstallFromWingetBlock Valve.Steam {
    DeleteDesktopShortcut Steam
    Set-RegistryValue "HKCU:\Software\Valve\Steam" RememberPassword 1
    Write-ManualStep "Set install location"
}

InstallFromWingetBlock EpicGames.EpicGamesLauncher {
    DeleteDesktopShortcut "Epic Games Launcher"
    . "${env:ProgramFiles(x86)}\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe"
    RemoveStartupRegistryKey EpicGamesLauncher
    $epicGamesSettingsFile = "$env:LocalAppData\EpicGamesLauncher\Saved\Config\Windows\GameUserSettings.ini"
        (Get-Content $epicGamesSettingsFile) -replace "\[Launcher\]", "`$0`nDefaultAppInstallLocation=D:\Installs\Epic Games" | Set-Content $epicGamesSettingsFile
        (Get-Content $epicGamesSettingsFile) -replace "\[.+?_General\]", "`$0`nNotificationsEnabled_Adverts=False" | Set-Content $epicGamesSettingsFile
}