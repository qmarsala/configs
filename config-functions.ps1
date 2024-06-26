$global:blocksOfInterest = @()

function Block([string]$Comment, [scriptblock]$ScriptBlock, [scriptblock]$CompleteCheck, [scriptblock]$UpdateAvailable, [scriptblock]$UpdateScript, [switch]$RequiresReboot) {
    if ($Run -and $Run -ne $Comment) {
        return
    }
    $blockDuration = [Diagnostics.Stopwatch]::StartNew()
    function Write-OrSilent([string]$Text, [System.ConsoleColor]$ForegroundColor) {
        if (!$Silent) {
            Write-Host $Text -ForegroundColor $ForegroundColor
        }
    }
    function Write-BlockDuration() {
        Write-OrSilent "Block duration: $($blockDuration.Elapsed)" Blue
    }
    Write-OrSilent ('*' * 100) DarkBlue
    Write-OrSilent $Comment DarkBlue
    if ($CompleteCheck -and (Invoke-Command $CompleteCheck)) {
        Write-OrSilent "Already done" Blue
        if ($Run) {
            Write-OrSilent "But running anyway as requested" Green
        }
        else {
            if ($UpdateAvailable -and (Invoke-Command $UpdateAvailable)) {
                Write-OrSilent "Updating" Green
                Invoke-Command $UpdateScript
                $global:blocksOfInterest += $Comment
            }
            Write-BlockDuration
            return
        }
    }
    if (!$DryRun) {
        if ($RequiresReboot) {
            Write-OrSilent "This will take effect after a reboot" Yellow
        }
        Invoke-Command $ScriptBlock
        if ($CompleteCheck) {
            $global:blocksOfInterest += $Comment
        }
    }
    else {
        Write-OrSilent "This block would execute" Green
    }
    Write-BlockDuration
}

function FirstRunBlock([string]$Comment, [scriptblock]$ScriptBlock, [switch]$RequiresReboot) {
    Block $Comment {
        Invoke-Command $ScriptBlock -ErrorVariable scriptBlockError
        if (!$scriptBlockError) {
            Add-Content C:\QLocal\backup\config.done.txt $Comment
        }
    }.GetNewClosure() {
        (Get-Content C:\QLocal\backup\config.done.txt -ErrorAction Ignore) -contains $Comment
    } -RequiresReboot:$RequiresReboot
}

function ConfigFollowup([string]$FileName, [scriptblock]$Followup) {
    Set-Content "$env:tmp\$FileName.ps1" {
        Write-Output "$FileName"
        . $git\configs\config-functions.ps1
        $Followup
        Write-Output "Done. Press Enter to close."
        Read-Host
    }.ToString().Replace('$FileName', $FileName).Replace('$Followup', $Followup)
    New-FileRunOnce $FileName "$env:tmp\$FileName.ps1"
    Add-Content C:\QLocal\backup\runonce.txt ". $env:tmp\$FileName.ps1"
}

function DeleteDesktopShortcut([string]$ShortcutName) {
    if ((Get-Content C:\QLocal\.delete-desktop-shortcuts.txt -ErrorAction Ignore) -notcontains $ShortcutName) {
        Add-Content C:\QLocal\.delete-desktop-shortcuts.txt $ShortcutName
    }
}

function WaitWhile([scriptblock]$ScriptBlock, [string]$WaitingFor) {
    Write-Host -ForegroundColor Yellow $WaitingFor -NoNewline
    while (Invoke-Command $ScriptBlock) {
        Write-Host -ForegroundColor Yellow "." -NoNewline
        sleep -s 10
    }
    Write-Host
}

function WaitForPath([string]$Path) {
    WaitWhile { !(Test-Path $Path) } "Waiting for path $Path"
}

function WaitWhileProcess([string]$ProcessName) {
    WaitWhile { Get-Process $ProcessName -ErrorAction Ignore } "Waiting for $ProcessName to close"
}

function Write-ManualStep([string]$Comment) {
    $esc = [char]27
    Write-Output "$esc[1;43;22;30;52mManual step:$esc[0;1;33m $Comment$esc[0m"
    Start-Sleep -Seconds ([Math]::Ceiling($Comment.Length / 10))
}

function ConfigureNotifications([string]$AppId) {
    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\$AppId" ShowInActionCenter 0
}

function InstallFromGitHubBlock([string]$User, [string]$Repo, [scriptblock]$AfterClone, [int]$CloneDepth) {
    Block "Install $User/$Repo" {
        if (!$CloneDepth) {
            git clone https://github.com/$User/$Repo.git $git\$Repo
        }
        else {
            git clone https://github.com/$User/$Repo.git $git\$Repo --depth $CloneDepth
        }
        if ($AfterClone) {
            pushd $git\$Repo
            if ($User -eq "qmarsala") {
                git set-email
            }
            Invoke-Command $AfterClone
            popd
        }
    } {
        Test-Path $git\$Repo
    }
}

function InstallFromGitHubAssetBlock([string]$User, [string]$Repo, [string]$Asset, [scriptblock]$Install, [scriptblock]$CompleteCheck) {
    Block "Install $User/$Repo/$Asset" {
        $asset = (iwr https://api.github.com/repos/$User/$Repo/releases/latest | ConvertFrom-Json).assets | ? { $_.name -like $Asset }
        $downloadUrl = $asset | select -exp browser_download_url
        $fileName = $asset | select -exp name
        Download-File $downloadUrl $env:tmp\$fileName
        if ($fileName -like "*.zip") {
            Expand-Archive $env:tmp\$fileName $env:tmp\$Repo
        }
        else {
            mkdir $env:tmp\$Repo
            mv $env:tmp\$fileName $env:tmp\$Repo\$fileName
        }
        pushd $env:tmp\$Repo
        Invoke-Command $Install
        popd
    } $CompleteCheck
}

function InstallFromWingetBlock {
    [CmdletBinding(DefaultParameterSetName = "DefaultArgs")]
    Param(
        [Parameter(ParameterSetName = "DefaultArgs", Mandatory, Position = 0)]
        [Parameter(ParameterSetName = "OverrideArgs", Mandatory, Position = 0)]
        [string]$AppId,
        [Parameter(ParameterSetName = "OverrideArgs", Position = 1)]
        [string]$OverrideArgs,
        [Parameter(ParameterSetName = "DefaultArgs", Position = 1)]
        [Parameter(ParameterSetName = "OverrideArgs", Position = 2)]
        [scriptblock]$AfterInstall,
        [Parameter(ParameterSetName = "DefaultArgs", Position = 2)]
        [Parameter(ParameterSetName = "OverrideArgs", Position = 3)]
        [switch]$NoUpdate
    )
    $updateAvailable = {
        winget upgrade | sls $AppId
    }
    $updateScript = {
        winget list $AppId -e
        if ($OverrideArgs) {
            winget upgrade --id $AppId --accept-package-agreements --override $OverrideArgs
        }
        else {
            winget upgrade --id $AppId --accept-package-agreements
        }
    }
    Block "Install $AppId" {
        if ($OverrideArgs) {
            winget install --id $AppId --accept-package-agreements --override $OverrideArgs
        }
        else {
            winget install --id $AppId --accept-package-agreements
        }
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
        if ($AfterInstall) {
            Invoke-Command $AfterInstall
        }
    } {
        winget list $AppId -e | sls $AppId
    } `
    ($NoUpdate ? $null : $updateAvailable) `
    ($NoUpdate ? $null : $updateScript)
}

function InstallFromScoopBlock([string]$AppId, [scriptblock]$AfterInstall) {
    Block "Install $AppId" {
        scoop install $AppId
        if ($AfterInstall) {
            Invoke-Command $AfterInstall
        }
    } {
        scoop export | sls $AppId
    } {
        scoop info $AppId | sls "Update to .+? available"
    } {
        scoop update $AppId
    }
}

function InstallVisualStudioExtensionBlock([string]$Publisher, [string]$Extension) {
    FirstRunBlock "Install VS Extension: $Publisher.$Extension" {
        $downloadUrl = (iwr "https://marketplace.visualstudio.com/items?itemName=$Publisher.$Extension" | sls "/_apis/public/gallery/publishers/$Publisher/vsextensions/$Extension/(\d+\.?)+/vspackage").Matches.Value | % { "https://marketplace.visualstudio.com$_" }
        $downloadTo = "$env:tmp\$Publisher.$Extension.vsix"
        Download-File $downloadUrl $downloadTo
        if (Test-Path $downloadTo) {
            $vsixInstaller = . "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -all -property productPath | Split-Path | % { "$_\VSIXInstaller.exe" }
            $installArgs = "/quiet", "/admin", $downloadTo
            Write-Output "Installing $Extension"
            Start-Process $vsixInstaller $installArgs -Wait
        }
        else {
            Write-Error "Could not download $Publisher.$Extension"
        }
    }
}

function InstallPowerShellModuleBlock([string]$ModuleName, [scriptblock]$AfterInstall) {
    Block "Install $ModuleName" {
        Install-Module $ModuleName -Force
        if ($AfterInstall) {
            Invoke-Command $AfterInstall
        }
    } {
        Get-Module -ListAvailable $ModuleName
    } {
        (Find-Module $ModuleName).Version -gt (Get-Module $ModuleName -ListAvailable | sort Version -Descending | select -First 1).Version
    } {
        Write-Output "Updating from $((Get-Module $ModuleName).Version) to $((Find-Module $ModuleName).Version)"
        ReallyUpdate-Module $ModuleName
    }
}

function UninstallBlock([string]$AppName) {
    Block "Uninstall $AppName" {
        winget uninstall $AppName
    } {
        !(winget list $AppName | sls $AppName)
    }
}
