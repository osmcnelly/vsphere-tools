function Test-EsxiAdvancedSetting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $setting = Get-VMHost -Name $VMHost | Get-AdvancedSetting -Name $Row.CheckName -ErrorAction SilentlyContinue
    if (-not $setting) {
        return [PSCustomObject]@{
            STIGID   = $Row.STIGID
            VID      = $Row.VID
            VMHost   = $VMHost
            Check    = "AdvancedSetting: $($Row.CheckName)"
            Expected = $Row.Expected
            Actual   = "Not Found"
            Result   = "Fail"
            Severity = $Row.Severity
        }
    }

    $pass = $setting.Value -eq $Row.Expected
    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "AdvancedSetting: $($Row.CheckName)"
        Expected = $Row.Expected
        Actual   = $setting.Value
        Result   = if ($pass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity
    }
}
