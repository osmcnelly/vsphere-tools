function Test-EsxiLocalLogPersistent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $esxcli = Get-VMHost -Name $VMHost | Get-EsxCli -V2
    $localLogPersistent = $esxcli.system.syslog.config.get.Invoke() | Select-object LocalLogOutputIsPersistent

    $actual = $localLogPersistent.LocalLogOutputIsPersistent
    $pass   = ($actual -eq $true -and $Row.Expected -eq "true")

    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "LocalLogPersistent"
        Expected = $Row.Expected
        Actual   = if ($actual -eq $true) { "True" } else { "False" }
        Result   = if ($pass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity
    }
}