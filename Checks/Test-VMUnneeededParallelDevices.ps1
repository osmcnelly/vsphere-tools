function Test-VMUnneededParallelDevices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][object]$VM
    )

    if ($VM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]) {
        $VM = Get-VM -Name $VM -ErrorAction Stop
    }

    $hwDevices = @()
    try { $hwDevices = $VM.ExtensionData.Config.Hardware.Device } catch { $hwDevices = @() }

    $parallelDevs  = @($hwDevices | Where-Object { $_.DeviceInfo.Label -match '(?i)\bparallel\b' })
    $parallelCount = $parallelDevs.Count
    $parallelNames = ($parallelDevs | ForEach-Object { $_.DeviceInfo.Label }) -join ', '

    $actual = "ParallelDeviceCount={0}; ParallelDevices={1}" -f $parallelCount, $parallelNames

    if ([string]::IsNullOrEmpty($Row.Expected)) { $exp = '' } else { $exp = $Row.Expected.Trim() }

    if ([string]::IsNullOrWhiteSpace($exp)) {
        if ($parallelCount -eq 0) { $result = 'Pass' } else { $result = 'Fail' }
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
