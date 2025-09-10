# Load all Test-* scripts from Checks folder
$moduleRoot = $PSScriptRoot
$checkDir   = Join-Path (Split-Path $moduleRoot -Parent) "Checks"

if (Test-Path $checkDir) {
    Get-ChildItem -Path $checkDir -Filter *.ps1 | ForEach-Object { . $_.FullName }
}

function Invoke-EsxiStigChecks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CsvPath,
        [Parameter(Mandatory)][string]$VMHost
    )

    $rows = Import-Csv -Path $CsvPath
    $results = @()

    foreach ($row in $rows) {
        try {
            switch ($row.CheckType) {
                "AdvancedSetting" { $results += Test-EsxiAdvancedSetting -Row $row -VMHost $VMHost }
                "Service"         { $results += Test-EsxiService -Row $row -VMHost $VMHost }
                "FirewallDefaultPolicy"    { $results += Test-EsxiFirewallDefaultPolicy -Row $row -VMHost $VMHost }
                "SshConfig"       { $results += Test-EsxiSshConfig -Row $row -VMHost $VMHost }
                "SecureBoot"      { $results += Test-EsxiSecureBoot -Row $row -VMHost $VMHost }
                "rhttpproxyDaemon" { $results += Test-rhttpproxyDaemon -Row $row -VMHost $VMHost}
                "StrictX509Compliance" { $results += Test-StrictX509Compliance -Row $row -VMHost $VMHost}
                "FirewallException" { $results += Test-EsxiFirewallException -Row $row -VMHost $VMHost}
                "TpmMode" { $results += Test-EsxiTpmMode -Row $row -VMHost $VMHost}
                "AuditRecords" { $results += Test-EsxiAuditRecords -Row $row -VMHost $VMHost}
                "LockdownMode" { $results+= Test-EsxiLockdownMode -Row $row -VMHost $VMHost}
                default {
                    $results += [PSCustomObject]@{
                        STIGID    = $row.STIGID
                        VID       = $row.VID
                        VMHost    = $VMHost
                        Check     = $row.CheckType
                        Expected  = $row.Expected
                        Actual    = $null
                        Result    = "Unsupported"
                        Severity  = $row.Severity
                        Timestamp = (Get-Date)
                    }
                }
            }
        }
        catch {
            Write-Warning "Check failed for $($row.VID): $_"
            $results += [PSCustomObject]@{
                STIGID    = $row.STIGID
                VID       = $row.VID
                VMHost    = $VMHost
                Check     = $row.CheckType
                Expected  = $row.Expected
                Actual    = "Error"
                Result    = "Fail"
                Severity  = $row.Severity
                Timestamp = (Get-Date)
            }
        }
    }

    return $results
}
