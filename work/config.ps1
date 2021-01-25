InstallFromScoopBlock OpenVPN openvpn {
    $openvpnExe = "$(scoop prefix openvpn)\bin\openvpn-gui.exe"
    $ovpnFile = (Read-Host "Path to .ovpn file").Trim('"')
    Copy-Item $ovpnFile $env:UserProfile\scoop\persist\openvpn\config
    New-Item "$env:AppData\Microsoft\Windows\Start Menu\Programs\BenCommands" -ItemType Directory -Force
    Create-Shortcut $openvpnExe "$env:AppData\Microsoft\Windows\Start Menu\Programs\BenCommands\vpnstart.lnk" "--connect $(Split-Path $ovpnFile -Leaf)"
    Create-Shortcut powershell "$env:AppData\Microsoft\Windows\Start Menu\Programs\BenCommands\vpnstop.lnk" "-WindowStyle Hidden `". '$openvpnExe' --command disconnect_all; . '$openvpnExe' --command exit`""
    . "$env:AppData\Microsoft\Windows\Start Menu\Programs\BenCommands\vpnstart.lnk"
    WaitWhile { !(Test-Path "HKCU:\Software\OpenVPN-GUI") } "Waiting for OpenVPN registry key"
    Set-ItemProperty "HKCU:\Software\OpenVPN-GUI" -Name silent_connection -Value 1
    ConfigureNotifications "OpenVPN GUI for Windows"
    if (!(Configured $forWork)) {
        . "$env:AppData\Microsoft\Windows\Start Menu\Programs\BenCommands\vpnstop.lnk"
    }
}

if ((Configured $forWork) -or (Configured $forTest)) {
    Block "Install Zoom" {
        iwr https://zoom.us/client/latest/ZoomInstaller.exe -OutFile "$env:tmp\ZoomInstaller.exe"
        . "$env:tmp\ZoomInstaller.exe"
        DeleteDesktopShortcut Zoom

        # Configure during install:
        #   https://support.zoom.us/hc/en-us/articles/201362163-Mass-Installation-and-Configuration-for-Windows#h_b82f0349-4d8f-45dd-898a-1ab98389a4b7
        #   Code
        #       iwr https://zoom.us/client/latest/ZoomInstallerFull.msi -OutFile "$env:tmp\ZoomInstallerFull.msi"
        #       msiexec /package "$env:tmp\ZoomInstallerFull.msi" ZRecommend="AutoHideToolbar=1"
        #   I can't get ZRecommend or ZConfig to work (settings are not changed)
        # Group policy:
        #   https://support.zoom.us/hc/en-us/articles/360039100051-Group-Policy-Options-for-the-Windows-Desktop-Client-and-Zoom-Rooms#h_e5b756c6-5e06-4a22-ad78-f19922a6e94f
        #   This works but the downside is the options are uneditable from the UI
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Zoom\Zoom Meetings\General" -Name AlwaysShowMeetingControls -Value 1
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Zoom\Zoom Meetings\General" -Name EnableRemindMeetingTime -Value 1
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Zoom\Zoom Meetings\General" -Name MuteWhenLockScreen -Value 1
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Zoom\Zoom Meetings\General" -Name TurnOffVideoCameraOnJoin -Value 1
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Zoom\Zoom Meetings\General" -Name AlwaysShowVideoPreviewDialog -Value 0
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Zoom\Zoom Meetings\General" -Name SetUseSystemDefaultMicForVOIP -Value 1
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Zoom\Zoom Meetings\General" -Name SetUseSystemDefaultSpeakerForVOIP -Value 1
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Zoom\Zoom Meetings\General" -Name AutoJoinVoIP -Value 1
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Zoom\Zoom Meetings\General" -Name MuteVoIPWhenJoinMeeting -Value 1
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Zoom\Zoom Meetings\General" -Name EnterFullScreenWhenViewingSharedScreen -Value 0
    } {
        Test-ProgramInstalled Zoom
    }

    InstallFromScoopBlock Postgres postgresql
    InstallFromGitHubBlock pluralsight psqlx {
        if (!(Test-Path $profile) -or !(Select-String "psqlx\.ps1" $profile)) {
            Add-Content -Path $profile -Value "`n"
            Add-Content -Path $profile -Value "`$psqlxRunner = `"psql`" # or `"docker`""
            Add-Content -Path $profile -Value ". $git\psqlx\psqlx.ps1"
        }
    }

    Block "Configure scoop java bucket and install Java" {
        scoop bucket add java
        scoop install adopt8-hotspot -a 32bit # Java 1.8 JDK; Metals for VS Code does not work with 64-bit
    } {
        scoop export | Select-String adopt8-hotspot
    }
    InstallFromScoopBlock SBT sbt
    InstallFromScoopBlock Scala scala
}