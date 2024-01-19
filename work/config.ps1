Block "Prevent `"Allow my organization to manage my device`"" {
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin" -Name BlockAADWorkplaceJoin -Value 1
}

if ((Configured $forWork) -or (Configured $forTest)) {
    Block "Install Zoom" {
        winget install Zoom.Zoom --scope machine --override `
        ('zNoDesktopShortCut="true"' + `
                ' ZRecommend="' + `
                'KeepSignedIn=1' + `
                ';AutoHideToolbar=0' + `
                ';EnableRemindMeetingTime=1' + `
                ';MuteWhenLockScreen=1' + `
                ';DisableVideo=1' + `
                ';AlwaysShowVideoPreviewDialog=0' + `
                ';SetUseSystemDefaultMicForVoip=1' + `
                ';SetUseSystemDefaultSpeakerForVoip=1' + `
                ';AutoJoinVOIP=1' + `
                ';MuteVoipWhenJoin=1' + `
                ';AutoFullScreenWhenViewShare=0' + `
                '"')

        . $env:ProgramFiles\Zoom\bin\Zoom.exe
        WaitForPath $env:AppData\Zoom\data\Zoom.us.ini
        Add-Content $env:AppData\Zoom\data\Zoom.us.ini "com.zoom.client.theme.mode=3"
    } {
        winget list Zoom.Zoom -e | sls Zoom.Zoom
    }

    if (!(Configured $forTest)) {
        InstallFromWingetBlock Docker.DockerDesktop {
            DeleteDesktopShortcut "Docker Desktop"
            RemoveStartupRegistryKey "Docker Desktop"
            WaitForPath $env:AppData\Docker\settings.json
            $dockerSettings = Get-Content $env:AppData\Docker\settings.json | ConvertFrom-Json
            $dockerSettings | Add-Member NoteProperty openUIOnStartupDisabled $true
            ConvertTo-Json $dockerSettings | Set-Content $env:AppData\Docker\settings.json
        }
    }

    InstallFromGitHubBlock benallred dc {
        if (!(Test-Path $profile) -or !(Select-String "dc\.ps1" $profile)) {
            Add-Content -Path $profile -Value "`n"
            Add-Content -Path $profile -Value ". $git\dc\dc.ps1"
        }
    }

    InstallFromScoopBlock mob
    InstallPowerShellModuleBlock Az
}
