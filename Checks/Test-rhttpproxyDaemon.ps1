function Test-rhttpproxyDaemon {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $esxcli = Get-VMHost -Name $VMHost | Get-EsxCli -V2
    $rhttpproxyStatus = $esxcli.system.security.fips140.rhttpproxy.get.invoke()

    $actual = $rhttpproxyStatus.Enabled
    $pass   = ($actual -eq $true -and $Row.Expected -eq "Enabled")

    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "rhttpproxyDaemon"
        Expected = $Row.Expected
        Actual   = if ($actual) { "Enabled" } else { "Disabled" }
        Result   = if ($pass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity
    }
}