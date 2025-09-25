function Test-VMAdvancedSetting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        # Accept either a VM object or a VM name
        [Parameter(Mandatory)][object]$VM
    )

    # Normalize to VM object
    if ($VM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]) {
        $VM = Get-VM -Name $VM -ErrorAction Stop
    }

    # Get-AdvancedSetting supports wildcards in -Name for VMs when using -Entity
    $settings = Get-AdvancedSetting -Entity $VM -Name $Row.CheckName -ErrorAction SilentlyContinue

    $exp  = ($Row.Expected  | ForEach-Object { $_.ToString().Trim() })  # may be empty
    $exp2 = ($Row.Expected2 | ForEach-Object { $_.ToString().Trim() })  # may be empty

    # ---- Expected is blank => setting must NOT exist ----
    if ([string]::IsNullOrWhiteSpace($exp)) {
        if (-not $settings) {
            return [PSCustomObject]@{
                STIGID   = $Row.STIGID
                VID      = $Row.VID
                VM       = $VM.Name
                Check    = "AdvancedSetting: $($Row.CheckName)"
                Expected = $Row.Expected
                Actual   = "(setting not present)"
                Result   = "Pass"
                Severity = $Row.Severity
                Timestamp= Get-Date
            }
        } else {
            $actualVals = ($settings | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '; '
            return [PSCustomObject]@{
                STIGID   = $Row.STIGID
                VID      = $Row.VID
                VM       = $VM.Name
                Check    = "AdvancedSetting: $($Row.CheckName)"
                Expected = $Row.Expected
                Actual   = $actualVals
                Result   = "Fail"
                Severity = $Row.Severity
                Timestamp= Get-Date
            }
        }
    }

    # ---- Special phrase: "FALSE or does not exist" ----
    if ($exp -match '^(?i:false\s+or\s+does\s+not\s+exist)$') {
        if (-not $settings) {
            return [PSCustomObject]@{
                STIGID   = $Row.STIGID
                VID      = $Row.VID
                VM       = $VM.Name
                Check    = "AdvancedSetting: $($Row.CheckName)"
                Expected = $Row.Expected
                Actual   = "(setting not present)"
                Result   = "Pass"
                Severity = $Row.Severity
                Timestamp= Get-Date
            }
        }
        $vals = $settings | ForEach-Object { $_.Value.ToString().Trim().ToUpper() }
        $allFalse = ($vals | Where-Object { $_ -ne 'FALSE' }).Count -eq 0
        return [PSCustomObject]@{
            STIGID   = $Row.STIGID
            VID      = $Row.VID
            VM       = $VM.Name
            Check    = "AdvancedSetting: $($Row.CheckName)"
            Expected = $Row.Expected
            Actual   = ($vals -join ', ')
            Result   = $(if ($allFalse) { "Pass" } else { "Fail" })
            Severity = $Row.Severity
            Timestamp= Get-Date
        }
    }

    # ---- Concrete Expected (and maybe Expected2) ----
    if (-not $settings) {
        return [PSCustomObject]@{
            STIGID   = $Row.STIGID
            VID      = $Row.VID
            VM       = $VM.Name
            Check    = "AdvancedSetting: $($Row.CheckName)"
            Expected = $Row.Expected
            Actual   = "(setting not present)"
            Result   = "Fail"
            Severity = $Row.Severity
            Timestamp= Get-Date
        }
    }

    $vals = $settings | ForEach-Object { $_.Value.ToString().Trim() }
    $ok = $true
    foreach ($v in $vals) {
        if ($exp2) {
            if ($v -ne $exp -and $v -ne $exp2) { $ok = $false }
        } else {
            if ($v -ne $exp) { $ok = $false }
        }
    }

    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VM       = $VM.Name
        Check    = "AdvancedSetting: $($Row.CheckName)"
        Expected = $Row.Expected
        Actual   = ($vals -join ', ')
        Result   = $(if ($ok) { "Pass" } else { "Fail" })
        Severity = $Row.Severity
        Timestamp= Get-Date
    }
}
