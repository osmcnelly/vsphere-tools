function Test-EsxiLockdownModeExceptionUserList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )
    
    $vmhost = Get-VMHost | Get-View
    $lockdown = Get-View $vmhost.ConfigManager.HostAccessManager
    $actual = $lockdown.QueryLockdownExceptions()
    $pass = ($null -eq $actual -and $Row.Expected -eq "None")
    
    [PSCustomObject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "LockdownModeExceptionUsersList"
        Expected = $Row.Expected
        Actual   = if ($actual) { "No Exception List Users" } else { $actual }
        Result   = if ($pass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity    
    }
}