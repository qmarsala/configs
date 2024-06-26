Block "Associate extensionless files with VS Code" {
    & "$PSScriptRoot\Associate Extensionless Files with VS Code.ps1"
}

Block "Create generic file handler" {
    Set-RegistryValue "HKLM:\SOFTWARE\Classes\Q.VSCode\shell\open\command" -Value """$env:LocalAppData\Programs\Microsoft VS Code\Code.exe"" ""%1"""
}

function CreateFileHandlerBlock([string]$Handler, [string]$DisplayName, [string]$DefaultIcon, [string]$OpenCommand) {
    Block "Create file handler $Handler" {
        Set-RegistryValue "HKCU:\SOFTWARE\Classes\$Handler" -Value $DisplayName
        Set-RegistryValue "HKCU:\SOFTWARE\Classes\$Handler\DefaultIcon" -Value $DefaultIcon
        Set-RegistryValue "HKCU:\SOFTWARE\Classes\$Handler\shell\open\command" -Value $OpenCommand
    }
}

function AssociateFileBlock([string]$Extension, [string]$Handler) {
    Block "Associate $Extension with $Handler" {
        Set-RegistryValue "HKCU:\SOFTWARE\Classes\.$($Extension.Trim('.'))" -Value $Handler
    }
}

function 7ZipFileBlock([string]$Extension, [int]$IconIndex) {
    $trimmedExtension = $Extension.Trim('.')
    $handler = "7-Zip.$trimmedExtension"
    CreateFileHandlerBlock $handler "$trimmedExtension Archive" "$env:ProgramFiles\7-Zip\7z.dll,$IconIndex" """$env:ProgramFiles\7-Zip\7zFM.exe"" ""%1"""
    AssociateFileBlock $Extension $handler
}

AssociateFileBlock txt VSCodeSourceFile
AssociateFileBlock log VSCodeSourceFile
AssociateFileBlock ps1 VSCodeSourceFile
AssociateFileBlock bat VSCodeSourceFile
AssociateFileBlock sh VSCodeSourceFile
AssociateFileBlock ini VSCodeSourceFile
AssociateFileBlock json VSCodeSourceFile
AssociateFileBlock xml VSCodeSourceFile
AssociateFileBlock config VSCodeSourceFile
AssociateFileBlock DotSettings VSCodeSourceFile
AssociateFileBlock nuspec VSCodeSourceFile
AssociateFileBlock cshtml VSCodeSourceFile
AssociateFileBlock creds VSCodeSourceFile
AssociateFileBlock pgpass VSCodeSourceFile
AssociateFileBlock yarnrc VSCodeSourceFile
AssociateFileBlock nvmrc VSCodeSourceFile

Block "Set .ahk Edit command to VS Code" {
    Set-RegistryValue "HKLM:\SOFTWARE\Classes\AutoHotkeyScript\Shell\Edit\Command" -Value "`"$env:LocalAppData\Programs\Microsoft VS Code\bin\code.cmd`" %1"
}

7ZipFileBlock 7z 0
7ZipFileBlock zip 1
7ZipFileBlock rar 3
7ZipFileBlock cab 7
7ZipFileBlock tar 13
7ZipFileBlock gz 14
7ZipFileBlock gzip 14
7ZipFileBlock nupkg 1
