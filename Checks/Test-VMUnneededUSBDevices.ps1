function Test-VMUnneededUSBDevices {
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

    $usbControllers = @($hwDevices | Where-Object { $_.DeviceInfo.Label -match '(?i)\busb\b' })
    $hasUsbController = $usbControllers.Count -gt 0

    $usbDevices = @()
    try { $usbDevices = Get-VM -Name $VM.Name | Get-UsbDevice -ErrorAction SilentlyContinue } catch { $usbDevices = @() }
    $usbDeviceCount = ($usbDevices | Measure-Object).Count

    $usbDeviceNames = ($usbDevices | Select-Object -ExpandProperty Name) -join ', '
    $actual = "UsbController={0}; UsbDeviceCount={1}; UsbDevices={2}" -f ($hasUsbController.ToString()), $usbDeviceCount, $usbDeviceNames

    if ([string]::IsNullOrEmpty($Row.Expected)) { $exp = '' } else { $exp = $Row.Expected.Trim() }
    if ([string]::IsNullOrEmpty($Row.Expected2)) { $exp2 = '' } else { $exp2 = $Row.Expected2.Trim() }

    if ([string]::IsNullOrWhiteSpace($exp) -and [string]::IsNullOrWhiteSpace($exp2)) {
        if (-not $hasUsbController -and $usbDeviceCount -eq 0) { $result = 'Pass' } else { $result = 'Fail' }
    } else {
        if ($actual -eq $exp -or ($exp2 -and $actual -eq $exp2)) { $result = 'Pass' } else { $result = 'Fail' }
    }

    [PSCustomObject]@{
        STIGID    = $Row.STIGID
        VID       = $Row.VID
        VM        = $VM.Name
        Check     = $Row.CheckType
        Expected  = if ($exp -or $exp2) { $exp + ($(if ($exp2) { "; $exp2" } else { "" })) } else { $Row.Expected }
        Actual    = $actual
        Result    = $result
        Severity  = $Row.Severity
        Timestamp = Get-Date
    }
}
