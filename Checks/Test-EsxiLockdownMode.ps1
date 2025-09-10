function Test-EsxiLockdownMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $vmh    = Get-VMHost -Name $VMHost
    $lockdownModeStatus = $vmh | Select-Object Name,@{N="Lockdown";E={$_.Extensiondata.Config.LockdownMode}}

    $actual = $lockdownModeStatus.Lockdown
    $pass   = ($actual -eq $true -and $Row.Expected -eq "Enabled")

    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "LockdownMode"
        Expected = $Row.Expected
        Actual   = if ($actual) { "Enabled" } else { "Disabled" }
        Result   = if ($pass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity
    }
}