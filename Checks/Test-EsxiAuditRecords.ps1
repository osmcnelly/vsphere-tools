function Test-EsxiAuditRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $vmh    = Get-VMHost -Name $VMHost
    $esxcli = Get-EsxCli -VMHost $vmh -V2
    $audit  = $esxcli.system.auditrecords.get.Invoke()

    $storageActive  = $audit.AuditRecordStorageActive
    $storageDir     = $audit.AuditRecordStorageDirectory
    $remoteActive   = $audit.AuditRecordRemoteTransmissionActive
    $capacity       = $audit.AuditRecordStorageCapacity

    # Basic compliance checks
    $passStorage = ($storageActive -eq $true)
    $passDir     = ($storageDir -and ($storageDir -notlike "/tmp*"))
    $overallPass = $passStorage -and $passDir

    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "AuditRecords"
        Expected = "StorageActive=True; Directory=Persistent"
        Actual   = "StorageActive=$storageActive; RemoteActive=$remoteActive; Directory=$storageDir; Capacity=$capacity"
        Result   = if ($overallPass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity
    }
}
