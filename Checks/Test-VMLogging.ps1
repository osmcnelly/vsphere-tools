function Test-VMLogging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][object]$VM
    )

    if ($VM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]) {
        $VM = Get-VM -Name $VM -ErrorAction Stop
    }

    $loggingEnabled = $null
    try { $loggingEnabled = $VM.ExtensionData.Config.Flags.EnableLogging } catch { $loggingEnabled = $null }

    $actual = "LoggingEnabled={0}" -f $loggingEnabled

    if ([string]::IsNullOrEmpty($Row.Expected)) { $exp = 'True' } else { $exp = $Row.Expected.Trim() }

    if ($loggingEnabled -eq $true -and $exp -ieq 'Enabled') { $result = 'Pass' } else { $result = 'Fail' }

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
