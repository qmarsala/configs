$src = (Resolve-Path "$PSScriptRoot\..\..")

git clone https://github.com/lukesampson/concfg.git $src\concfg
. $src\concfg\bin\concfg.ps1 import vs-code-dark-plus -n
. $src\concfg\bin\concfg.ps1 clean

Install-Module posh-git
Add-PoshGitToProfile -AllHosts

mkdir "C:\BenLocal\PowerShell Transcripts" -ErrorAction Ignore

if (!(Test-Path $profile) -or !(Select-String "$src\\configs\\powershell\\profile.ps1" $profile))
{
	Add-Content -Path $profile -Value "`n. $src\configs\powershell\profile.ps1"
}

. $profile

Update-Help
