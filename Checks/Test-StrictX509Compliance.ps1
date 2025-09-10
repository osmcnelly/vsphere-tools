function Test-StrictX509Compliance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $esxcli = Get-VMHost -Name $VMHost | Get-EsxCli -V2
    $StrictX509ComplianceStatus = $esxcli.system.syslog.config.get.invoke()|Select-Object StrictX509Compliance

    $actual = $StrictX509ComplianceStatus.StrictX509Compliance
    $pass   = ($actual -eq $true -and $Row.Expected -eq "Enabled")

    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "StrictX509Compliance"
        Expected = $Row.Expected
        Actual   = if ($actual) { "Enabled" } else { "Disabled" }
        Result   = if ($pass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity
    }
}