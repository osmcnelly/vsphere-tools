function Test-VMUnneededDiskDrives {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][object]$VM
    )

    if ($VM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]) {
        $VM = Get-VM -Name $VM -ErrorAction Stop
    }

    $cds = @()
    try { $cds = Get-VM -Name $VM.Name | Get-CDDrive -ErrorAction SilentlyContinue } catch { $cds = @() }

    $totalCount      = ($cds | Measure-Object).Count
    $connectedDrives = @($cds | Where-Object { $_.ExtensionData.Connectable.Connected -eq $true })
    $connectedCount  = $connectedDrives.Count
    $connectedNames  = ($connectedDrives | ForEach-Object { $_.Name }) -join ', '

    $actual = "CdDriveCount={0}; ConnectedCount={1}; Connected={2}" -f $totalCount, $connectedCount, $connectedNames

    if ([string]::IsNullOrWhiteSpace($Row.Expected)) { $exp = 'Disconnected' } else { $exp = $Row.Expected.Trim() }

    if ($exp -ieq 'Disconnected') {
        if ($connectedCount -eq 0) { $result = 'Pass' } else { $result = 'Fail' }
    } else {
        if ($actual -eq $exp) { $result = 'Pass' } else { $result = 'Fail' }
    }

    [PSCustomObject]@{
        STIGID    = $Row.STIGID
        VID       = $Row.VID
        VM        = $VM.Name
        Check     = $Row.CheckType
        Expected  = $exp
        Actual    = $actual
        Result    = $result
        Severity  = $Row.Severity
        Timestamp = Get-Date
    }
}
