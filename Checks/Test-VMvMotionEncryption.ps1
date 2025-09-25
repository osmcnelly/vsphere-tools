function Test-VMvMotionEncryption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][object]$VM
    )

    if ($VM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]) {
        $VM = Get-VM -Name $VM -ErrorAction Stop
    }

    $encMode = $null
    try { $encMode = $VM.ExtensionData.Config.MigrateEncryption } catch { $encMode = $null }

    $actual = "vMotionEncryption={0}" -f $encMode

    if ([string]::IsNullOrEmpty($Row.Expected)) { $exp = 'Opportunistic' } else { $exp = $Row.Expected.Trim() }

    if ($encMode -and ($encMode -ieq $exp)) { $result = 'Pass' } else { $result = 'Fail' }

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
