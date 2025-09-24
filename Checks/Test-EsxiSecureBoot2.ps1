function Test-EsxiSecureBoot2 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $secureBootcompatibility = ((Get-VMHost).ExtensionData.Capability).UefiSecureBoot

    $actual = $secureBootcompatibility
    $pass   = ($actual -eq $true -and $Row.Expected -eq "Enabled")

    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "SecureBoot2"
        Expected = $Row.Expected
        Actual   = if ($actual -eq $true) { "Enabled" } else { "Disabled" }
        Result   = if ($pass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity
    }
}
