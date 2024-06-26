. $PSScriptRoot\..\functions.ps1

$runTimeId = "monthly"

if (AlreadyRunThisMonth $runTimeId) {
    return
}

mkdir $tmp -ErrorAction Ignore | Out-Null

function Backup([string]$From, [string]$To, [switch]$IsMediaBackup) {
    $logFile = "$To.log"
    Write-Output "Backing up $From to $To"
    Write-Output "Writing log file to $logFile"
    # /J           = copy using unbuffered I/O (recommended for large files)
    $mediaBackupSwitches = $IsMediaBackup ? "/J" : ""
    # /Z           = copy files in restartable mode
    # /DCOPY:T     = COPY Directory Timestamps
    # /MIR         = MIRror a directory tree (equivalent to /E plus /PURGE)
    # /X           = report all eXtra files, not just those selected
    # /NDL         = No Directory List - don't log directory names
    # /NP          = No Progress - don't display percentage copied
    # /UNILOG:file = output status to LOG file as UNICODE (overwrite existing log)
    # /TEE         = output to console window, as well as the log file
    StopOnError 4 { robocopy $From $To /Z /DCOPY:T /MIR /X /NDL /NP /UNILOG:"$logFile" /TEE $mediaBackupSwitches }
    start $logFile
}

function BackupByMonth([string]$From, [string]$ToBase) {
    # 12 months of backups
    # $MonthAbbr = Get-Date -Format "MMM"
    # $MonthNumber = Get-Date -Format "MM"
    # 3 months of backups
    $monthAbbr = switch ((Get-Date).Month % 3) {
        1 { "Jan,Apr,Jul,Oct" }
        2 { "Feb,May,Aug,Nov" }
        0 { "Mar,Jun,Sep,Dec" }
    }
    $monthNumber = switch ((Get-Date).Month % 3) {
        0 { 3 }
        Default { $_ }
    }
    $to = "$ToBase\$monthNumber $monthAbbr"
    Backup $From $to
}

function BackupOneDrive() {
    $from = "$env:UserProfile\OneDrive"
    $to = "E:\Backup - Monthly\OneDrive"
    $logFile = "$to.log"
    Write-Output "Backing up $from to $to"
    Write-Output "Writing log file to $logFile"
    StopOnError 4 { robocopy $from $to /XD $env:UserProfile\OneDrive\Q $env:UserProfile\OneDrive\QEx $env:UserProfile\OneDrive\Music /XF (Get-ChildItem $env:UserProfile\OneDrive\ -Hidden) /Z /DCOPY:T /MIR /X /NDL /NP /UNILOG:"$logFile" /TEE }
    start $logFile
}