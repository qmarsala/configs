##################################################
# QMK

function qmk-ps([Parameter(ValueFromRemainingArguments = $true)]$Rest) {
    C:\QMK_MSYS\shell_connector.cmd -c "qmk $Rest"
}

function flash() {
    qmk-ps compile -kb moonlander -km q
    qmk-ps flash -kb moonlander -km q
}

##################################################
# AWS

function Update-AwsAccessKey() {
    Write-Output "Creating new access key"
    $newKey = aws iam create-access-key | ConvertFrom-Json | select -exp AccessKey
    aws configure set aws_access_key_id $newKey.AccessKeyId
    sleep -s 1 # the second set below sometimes fails because the first one still has the file locked
    aws configure set aws_secret_access_key $newKey.SecretAccessKey
    Write-Output "`t$($newKey.AccessKeyId.Substring($newKey.AccessKeyId.Length - 3, 3))"

    Write-Output "Waiting 10 seconds because AWS doesn't seem to acknowledge the new key right away"
    sleep -s 10

    Write-Output "Getting all keys"
    $allKeys = aws iam list-access-keys | ConvertFrom-Json | select -exp AccessKeyMetadata
    if ($allKeys.Length -le 1) {
        Write-Error "Expected more than one key"
        return
    }
    elseif ($allKeys.Length -gt 2) {
        Write-Output "`tFound $($allKeys.Length) keys"
    }

    Write-Output "Deleting oldest key"
    $oldKey = $allKeys | sort { $_.CreateDate } | select -First 1 | select -exp AccessKeyId
    Write-Output "`t$($oldKey.Substring($oldKey.Length - 3, 3))"
    aws iam delete-access-key --access-key-id $oldKey
}
