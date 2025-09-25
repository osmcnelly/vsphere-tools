function Test-VMFTEncryption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        # Accept a VM object or a VM name
        [Parameter(Mandatory)][object]$VM
    )

    # --- Normalize to VM object ---
    if ($VM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]) {
        $VM = Get-VM -Name $VM -ErrorAction Stop
    }

    # --- FT state ---
    $ftState = $null
    try { $ftState = $VM.ExtensionData.Runtime.FaultToleranceState } catch { $ftState = $null }

    # If FT is not enabled, STIG is NotApplicable
    $isFtEnabled = $false
    if ($ftState -eq 'enabled') { $isFtEnabled = $true }

    # --- FT encryption mode (only relevant if FT enabled) ---
    $ftEncMode = $null
    if ($isFtEnabled) {
        try { $ftEncMode = $VM.ExtensionData.Config.FtEncryptionMode } catch { $ftEncMode = $null }
    }

    # Canonical Actual string
    $actual = "FTState={0}; FTEncryption={1}" -f $ftState, $ftEncMode

    # Expected from CSV (single value; default to Opportunistic if blank)
    if ([string]::IsNullOrEmpty($Row.Expected)) { $exp = 'Opportunistic' } else { $exp = $Row.Expected.Trim() }

    # Determine result
    if (-not $isFtEnabled) {
        $result = 'NotApplicable'
    } else {
        if ($ftEncMode -and ($ftEncMode -ieq $exp)) { $result = 'Pass' } else { $result = 'Fail' }
    }

    # Emit in your standard schema
    [PSCustomObject]@{
        STIGID    = $Row.STIGID
        VID       = $Row.VID
        VM        = $VM.Name
        Check     = $Row.CheckType     # e.g., "FTEncryption"
        Expected  = $exp
        Actual    = $actual
        Result    = $result
        Severity  = $Row.Severity
        Timestamp = Get-Date
    }
}
