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

    # ---- Pattern: "<ExpectedValue> or does not exist" (case-insensitive) ----
    if ($exp -match '^(?i:(?<want>.+?)\s+or\s+does\s+not\s+exist)$') {
        # Normalize the expected value (strip quotes, trim, uppercase for CI compare)
        $want = $matches['want'].Trim().Trim("'`"").ToUpper()

        if (-not $settings) {
            return [PSCustomObject]@{
                STIGID    = $Row.STIGID
                VID       = $Row.VID
                VM        = $VM.Name
                Check     = "AdvancedSetting: $($Row.CheckName)"
                Expected  = $Row.Expected
                Actual    = "(setting not present)"
                Result    = "Pass"
                Severity  = $Row.Severity
                Timestamp = Get-Date
            }
        }

        # Collect and normalize actual values
        $vals = $settings |
            ForEach-Object { [string]$_.Value } |
            ForEach-Object { $_.Trim().Trim("'`"").ToUpper() }

        # Pass only if ALL values match the expected value
        $allMatch = ($vals | Where-Object { $_ -ne $want }).Count -eq 0

        return [PSCustomObject]@{
            STIGID    = $Row.STIGID
            VID       = $Row.VID
            VM        = $VM.Name
            Check     = "AdvancedSetting: $($Row.CheckName)"
            Expected  = $Row.Expected
            Actual    = ($vals -join ', ')
            Result    = if ($allMatch) { "Pass" } else { "Fail" }
            Severity  = $Row.Severity
            Timestamp = Get-Date
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
