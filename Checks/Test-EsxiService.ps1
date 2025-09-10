function Test-EsxiService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $service = Get-VMHost -Name $VMHost | Get-VMHostService | Where-Object { $_.Label -eq $Row.CheckName }
    if (-not $service) {
        return [PSCustomObject]@{
            STIGID   = $Row.STIGID
            VID      = $Row.VID
            VMHost   = $VMHost
            Check    = "Service: $($Row.CheckName)"
            Expected = "$($Row.Expected)/$($Row.Expected2)"
            Actual   = "Not Found"
            Result   = "Fail"
            Severity = $Row.Severity
        }
    }

    $actual = "$($service.Running)/$($service.Policy)"
    $expected = "$($Row.Expected)/$($Row.Expected2)"
    $pass = ($service.Running -eq ($Row.Expected -eq "Running")) -and ($service.Policy -eq $Row.Expected2)

    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "Service: $($Row.CheckName)"
        Expected = $expected
        Actual   = $actual
        Result   = if ($pass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity
    }
}
