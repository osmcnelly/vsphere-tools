function Test-SnmpStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $snmpStatus = Get-VMHostSnmp | Select-Object Enabled
    $actual = $snmpStatus.Enabled

    $pass   = ($actual -eq $false -and $Row.Expected -eq "Disabled")

    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "SNMPStatus"
        Expected = $Row.Expected
        Actual   = if ($actual -eq $false) { "Disabled" } else { "Enabled" }
        Result   = if ($pass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity
    }
}