function Test-VMUnneededFloppyDrives {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][object]$VM
    )

    if ($VM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]) {
        $VM = Get-VM -Name $VM -ErrorAction Stop
    }

    $floppies = @()
    try { $floppies = Get-VM -Name $VM.Name | Get-FloppyDrive -ErrorAction SilentlyContinue } catch { $floppies = @() }

    $totalCount      = ($floppies | Measure-Object).Count
    $connectedDrives = @($floppies | Where-Object { $_.ConnectionState.Connected -eq $true })
    $connectedCount  = $connectedDrives.Count
    $connectedNames  = ($connectedDrives | ForEach-Object { $_.Name }) -join ', '

    $actual = "FloppyCount={0}; ConnectedCount={1}; Connected={2}" -f $totalCount, $connectedCount, $connectedNames

    if ([string]::IsNullOrEmpty($Row.Expected)) { $exp = '' } else { $exp = $Row.Expected.Trim() }

    if ([string]::IsNullOrWhiteSpace($exp)) {
        if ($connectedCount -eq 0) { $result = 'Pass' } else { $result = 'Fail' }
    } else {
        if ($actual -eq $exp) { $result = 'Pass' } else { $result = 'Fail' }
    }

    [PSCustomObject]@{
        STIGID    = $Row.STIGID
        VID       = $Row.VID
        VM        = $VM.Name
        Check     = $Row.CheckType
        Expected  = if ($exp) { $exp } else { $Row.Expected }
        Actual    = $actual
        Result    = $result
        Severity  = $Row.Severity
        Timestamp = Get-Date
    }
}
