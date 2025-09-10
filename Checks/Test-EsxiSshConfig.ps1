# Test-EsxiSshConfig.ps1
# Retrieves sshd -T output once per host and validates SSH configuration directives.

# Per-run cache of parsed sshd config
$script:SshConfigCache = @{}

function Get-EsxiSshConfig {
    <#
      .SYNOPSIS
        Retrieves and caches sshd -T config output for an ESXi host.

      .PARAMETER VMHost
        ESXi hostname or IP.

      .OUTPUTS
        Hashtable of sshd directives keyed by directive name (lowercase).
        Each value is stored as "key value" (e.g., "ignorerhosts yes").
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$VMHost
    )

    if ($script:SshConfigCache.ContainsKey($VMHost)) {
        return $script:SshConfigCache[$VMHost]
    }

    $cmd = '/usr/lib/vmware/openssh/bin/sshd -T'
    $r   = Invoke-EsxiSsh -VMHost $VMHost -Command $cmd

    if ($r.ExitStatus -ne 0 -or -not $r.Output) {
        throw "Failed to retrieve sshd config from ${VMHost}: $($r.Errors)"
    }

    $dict = @{}
    foreach ($line in ($r.Output -split "`n")) {
        if ($line -match '^\s*(\S+)\s+(.+)$') {
            $key   = $matches[1].ToLower()
            $value = $matches[1].ToLower() + " " + $matches[2].Trim()
            $dict[$key] = $value
        }
    }

    $script:SshConfigCache[$VMHost] = $dict
    return $dict
}

function Test-EsxiSshConfig {
    <#
      .SYNOPSIS
        Validates one sshd_config directive against expected value.

      .DESCRIPTION
        Expects a CSV “row” object with fields like:
        STIGID, VID, CheckType=SshConfig, CheckName=<directive>, Expected=<value>, Severity.
        Compares directive value from sshd -T against Expected.

      .PARAMETER Row
        PSCustomObject for a single CSV row.

      .PARAMETER VMHost
        ESXi hostname or IP.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][string]$VMHost
    )

    try {
        $dict = Get-EsxiSshConfig -VMHost $VMHost
    }
    catch {
        return [pscustomobject]@{
            STIGID   = $Row.STIGID
            VID      = $Row.VID
            VMHost   = $VMHost
            Check    = "SshConfig: $($Row.CheckName)"
            Expected = $Row.Expected
            Actual   = "Error: $_"
            Result   = "Fail"
            Severity = $Row.Severity
        }
    }

    $key    = $Row.CheckName.ToLower()
    $actual = if ($dict.ContainsKey($key)) { $dict[$key] } else { $null }

    $expectedNorm = ($Row.Expected -replace '\s+', ' ').Trim().ToLower()
    $actualNorm   = if ($actual) { ($actual -replace '\s+', ' ').Trim().ToLower() } else { "" }

    $pass = ($expectedNorm -eq $actualNorm)

    return [pscustomobject]@{
        STIGID   = $Row.STIGID
        VID      = $Row.VID
        VMHost   = $VMHost
        Check    = "SshConfig: $($Row.CheckName)"
        Expected = $Row.Expected
        Actual   = if ($actual) { $actual } else { "Directive not found" }
        Result   = if ($pass) { "Pass" } else { "Fail" }
        Severity = $Row.Severity
    }
}
