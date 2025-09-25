function Test-VMUnneededSerialDevices {
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

    $serialDevs  = @($hwDevices | Where-Object { $_.DeviceInfo.Label -match '(?i)\bserial\b' })
    $serialCount = $serialDevs.Count
    $serialNames = ($serialDevs | ForEach-Object { $_.DeviceInfo.Label }) -join ', '

    $actual = "SerialDeviceCount={0}; SerialDevices={1}" -f $serialCount, $serialNames

    if ([string]::IsNullOrEmpty($Row.Expected)) { $exp = '' } else { $exp = $Row.Expected.Trim() }

    if ([string]::IsNullOrWhiteSpace($exp)) {
        if ($serialCount -eq 0) { $result = 'Pass' } else { $result = 'Fail' }
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
