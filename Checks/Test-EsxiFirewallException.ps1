function Test-EsxiFirewallException {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $vmh = Get-VMHost -Name $VMHost
    $exceptions = Get-VMHostFirewallException -VMHost $vmh | Where-Object { $_.Enabled -eq $true }

    $results = @()

    foreach ($rule in $exceptions) {
        $allIp = $rule.ExtensionData.AllowedHosts.AllIP
        $pass = ($allIp -eq $false)

        $results += [PSCustomObject]@{
            STIGID   = $Row.STIGID
            VID      = $Row.VID
            VMHost   = $VMHost
            Check    = "FirewallException: $($rule.Name)"
            Expected = "AllIP=False"
            Actual   = "AllIP=$allIp"
            Result   = if ($pass) { "Pass" } else { "Fail" }
            Severity = $Row.Severity
        }
    }

    return $results
}
