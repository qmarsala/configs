function Block([string]$Comment, [scriptblock]$ScriptBlock, [scriptblock]$CompleteCheck, [switch]$RequiresReboot) {
    if ($Run -and $Run -ne $Comment) {
        return
    }
    Write-Output (New-Object System.String -ArgumentList ('*', 100))
    Write-Output $Comment
    if ($CompleteCheck -and (Invoke-Command $CompleteCheck)) {
        Write-Output "Already done"
        if (!$Run) {
            return
        }
        else {
            Write-Output "But running anyway as requested"
        }
    }
    if (!$DryRun) {
        if ($RequiresReboot) {
            Write-Host "This will take effect after a reboot" -ForegroundColor Yellow
        }
        Invoke-Command $ScriptBlock
    }
    else {
        Write-Host "This block would execute" -ForegroundColor Green
    }
}

function FirstRunBlock([string]$Comment, [scriptblock]$ScriptBlock, [switch]$RequiresReboot) {
    Block $Comment {
        Invoke-Command $ScriptBlock
        Add-Content C:\BenLocal\backup\config.done.txt $Comment
    }.GetNewClosure() {
        (Get-Content C:\BenLocal\backup\config.done.txt -ErrorAction Ignore) -contains $Comment
    } -RequiresReboot:$RequiresReboot
}

function Write-ManualStep([string]$Comment) {
    $esc = [char]27
    Write-Output "$esc[1;43;22;30;52mManual step:$esc[0;1;33m $Comment$esc[0m"
    Start-Sleep -Seconds ([Math]::Ceiling($Comment.Length / 10))
}

function ConfigureNotifications([string]$ProgramName) {
    while (Get-Process SystemSettings -ErrorAction Ignore) {
        Write-Host -ForegroundColor Yellow "Waiting for the Settings app to close"
        sleep -s 10
    }
    Write-ManualStep "Configure notifications for: $ProgramName"
    start ms-settings:notifications
    Write-ManualStep "`tShow notifications in action center = Off"
    Write-ManualStep "`tClose settings when done"
}
