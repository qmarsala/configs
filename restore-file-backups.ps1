if (Test-Path C:\Q) {
    throw "About to overwrite master copies"
}

. $PSScriptRoot\scheduled-tasks\functions.ps1

function RestoreBackup([string]$From, [string]$To, [string]$LogFilePart) {
    $LogFilePart ??= (Split-Path $From -Leaf)
    $logFile = "C:\QLocal\backup\restore-$LogFilePart.log"
    Write-Output "Restoring $From to $To"
    Write-Output "Writing log file to $logFile"
    # /Z           = copy files in restartable mode
    # /DCOPY:T     = COPY Directory Timestamps
    # /MIR         = MIRror a directory tree (equivalent to /E plus /PURGE)
    # /X           = report all eXtra files, not just those selected
    # /NDL         = No Directory List - don't log directory names
    # /NP          = No Progress - don't display percentage copied
    # /UNILOG:file = output status to LOG file as UNICODE (overwrite existing log)
    # /TEE         = output to console window, as well as the log file
    StopOnError 4 { robocopy $From $To /Z /DCOPY:T /MIR /X /NDL /NP /UNILOG:"$logFile" /TEE }
}

function RestoreDailyBackup([string]$FromBase, [string]$To) {
    $weekday = Get-Date -Format "ddd"
    $weekdayNumber = (Get-Date).DayOfWeek.value__
    $from = "$FromBase\$weekdayNumber $weekday"
    RestoreBackup $from $To (Split-Path $FromBase -Leaf)
}

function RestoreMonthlyBackup([string]$FromBase, [string]$To) {
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
    $from = "$FromBase\$monthNumber $monthAbbr"
    RestoreBackup $from $To (Split-Path $FromBase -Leaf)
}
