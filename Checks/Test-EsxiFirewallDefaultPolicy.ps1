function Test-EsxiFirewallDefaultPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    $vmh = Get-VMHost -Name $VMHost
    $policy = Get-VMHostFirewallDefaultPolicy -VMHost $vmh

    $incomingPass = ($policy.IncomingEnabled -eq [System.Convert]::ToBoolean($Row.Expected))
    $outgoingPass = ($policy.OutgoingEnabled -eq [System.Convert]::ToBoolean($Row.Expected2))

    $result = if ($incomingPass -and $outgoingPass) { "Pass" } else { "Fail" }

    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "FirewallDefaultPolicy"
        Expected = "Incoming=$($Row.Expected); Outgoing=$($Row.Expected2)"
        Actual   = "Incoming=$($policy.IncomingEnabled); Outgoing=$($policy.OutgoingEnabled)"
        Result   = $result
        Severity = $Row.Severity
    }
}
