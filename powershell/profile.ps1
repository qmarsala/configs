$OneDrive = "$env:UserProfile\OneDrive"
$git = "C:\BenLocal\git"

function Set-WindowTitle($title) {
    $GitPromptSettings.EnableWindowTitle = ""
    $Host.UI.RawUI.WindowTitle = $title
}

function Reset-WindowTitle($title) {
    $GitPromptSettings.EnableWindowTitle = "Git:"
    $Host.UI.RawUI.WindowTitle = "PowerShell"
}

function Create-Shortcut($Target, $Link, $Arguments) {
    $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($Link)
    $shortcut.TargetPath = $Target
    $shortcut.WorkingDirectory = Split-Path $Target
    $shortcut.Arguments = $Arguments
    $shortcut.Save()
}

function Create-RunOnce([string]$Description, [string]$Command) {
    # https://docs.microsoft.com/en-us/windows/win32/setupapi/run-and-runonce-registry-keys
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name $Description -Value $Command
}

function Get-TimestampForFileName() {
    (Get-Date -Format o) -replace ":", "_"
}

function TestPathOrNewItem([string]$path) {
    if (!(Test-Path $path)) {
        New-Item $path -Force
    }
}

function SecureRead-Host([string]$Prompt) {
    $secureString = Read-Host -Prompt $Prompt -AsSecureString
    $binaryString = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    $string = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($binaryString)
    return $string
}

# fix for https://github.com/PowerShell/PowerShell/issues/7130
# can be removed when https://github.com/PowerShell/PSReadLine/pull/711 update makes it through
Set-PSReadLineKeyHandler Shift+Spacebar -ScriptBlock { [Microsoft.PowerShell.PSConsoleReadLine]::Insert(" ") }

$transcriptDir = "C:\BenLocal\PowerShell Transcripts"
Get-ChildItem "$transcriptDir\*.log" | ? { !(sls -Path $_ -Pattern "Command start time:" -SimpleMatch -Quiet) } | rm -ErrorAction SilentlyContinue
$Transcript = "$transcriptDir\$(Get-TimestampForFileName).log"
Start-Transcript $Transcript -NoClobber -IncludeInvocationHeader

if ((Get-Location) -like "*system32") {
    Set-Location $git
}
