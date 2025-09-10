function Test-EsxiSecureBoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $esxcli = Get-VMHost -Name $VMHost | Get-EsxCli -V2
    $bootStatus = $esxcli.system.settings.encryption.get.Invoke()

    $actual = $bootStatus.RequireSecureBoot
    $pass   = ($actual -eq $true -and $Row.Expected -eq "Enabled")

    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "SecureBoot"
        Expected = $Row.Expected
        Actual   = if ($actual -eq $true) { "Enabled" } else { "Disabled" }
        Result   = if ($pass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity
    }
}
