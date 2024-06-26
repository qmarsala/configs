param([switch]$DryRun, [switch]$SkipBackup, [string]$Run)

$totalDuration = [Diagnostics.Stopwatch]::StartNew()

. $PSScriptRoot\config-functions.ps1
mkdir C:\QLocal\backup -ErrorAction Ignore

Block "Configure for" {
    $configureForOptions = {
        $forHome = "home"
        $forWork = "work"
        $forTest = "test"
    }
    . $configureForOptions

    while (($configureFor = (Read-Host "Configure for ($forHome,$forWork,$forTest)")) -notin @($forHome, $forWork, $forTest)) { }

    if (!(Test-Path $profile)) {
        New-Item $profile -Force
    }

    Add-Content -Path $profile -Value "`n"
    Add-Content -Path $profile $configureForOptions
    Add-Content -Path $profile -Value "`$configureFor = `"$configureFor`""
    Add-Content -Path $profile {
        function Configured([Parameter(Mandatory = $true)][ValidateSet("home", "work", "test")][string]$for) {
            if (!$configureFor) {
                throw '$configureFor not set'
            }
            $for -eq $configureFor
        }
    }
} {
    (Test-Path $profile) -and (Select-String "\`$configureFor" $profile) # -Pattern is regex
}
if (!$DryRun -and !$Run) { . $profile } # make profile available to scripts below

Block "Backup Registry" {
    if (!(Configured $forTest)) {
        & $PSScriptRoot\backup-registry.ps1
    }
} {
    $SkipBackup
}

if (Configured $forHome) {
    FirstRunBlock "Change drive letters" {
        # Consider using Set-Partition or Set-Volume
        start diskmgmt.msc
        Write-ManualStep "Change drive letters"
        Read-Host "Press Enter when done"
    }

    Block "Restore file backups" {
        wt -w 0 nt pwsh -NoExit -File $PSScriptRoot\restore-file-backups.ps1
    } {
        Test-Path C:\Q
    }
}

& $PSScriptRoot\powershell\config.ps1
if (!$DryRun -and !$Run) {
    . $profile.AllUsersAllHosts
    . $profile.AllUsersCurrentHost
    . $profile.CurrentUserAllHosts
    . $profile.CurrentUserCurrentHost
    Update-WindowsTerminalSettings
}

Block "Git config" {
    git config --global --add include.path $PSScriptRoot\git\q.gitconfig
} {
    (git config --get-all --global include.path) -match "q\.gitconfig"
}

& $PSScriptRoot\windows\config.ps1
& $PSScriptRoot\install\install.ps1
if (Configured $forHome) {
    & $PSScriptRoot\install\games.ps1
}
& $PSScriptRoot\work\config.ps1
# & $PSScriptRoot\scheduled-tasks\config.ps1

Block "Blocks of interest this run" {
    $global:blocksOfInterest | % { Write-Output "`t$_" }
} {
    $global:blocksOfInterest.Length -eq 0
}

Write-Output "Total duration: $($totalDuration.Elapsed)"
