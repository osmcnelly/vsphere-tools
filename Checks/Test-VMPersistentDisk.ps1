function Test-VMPersistentDisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Row,
        [Parameter(Mandatory)][object]$VM
    )

    if ($VM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]) {
        $VM = Get-VM -Name $VM -ErrorAction Stop
    }

    $disks = @()
    try { $disks = Get-VM -Name $VM.Name | Get-HardDisk -ErrorAction SilentlyContinue } catch { $disks = @() }

    $diskFacts = foreach ($d in $disks) {
        $mode = $null
        try { $mode = $d.ExtensionData.Backing.DiskMode } catch { $mode = $null }
        if (-not $mode) {
            $p = ($d.Persistence | Out-String).Trim()
            if ($p) { $mode = $p.ToLower() } else { $mode = 'unknown' }
        }
        [pscustomobject]@{
            Name        = $d.Name
            Filename    = $d.Filename
            DiskMode    = $mode
            Persistence = $d.Persistence
        }
    }

    $offenders = @(
        $diskFacts | Where-Object {
            ($_.DiskMode -match '(?i)independent.*nonpersistent') -or
            ($_.DiskMode -match '(?i)nonpersistent') -or
            ($_.Persistence -match '(?i)nonpersistent')
        }
    )

    $offenderNames = ($offenders | Select-Object -ExpandProperty Name) -join ', '
    $nonPersistentCount = $offenders.Count
    $totalDisks = $diskFacts.Count
    $modeSummary = ($diskFacts | ForEach-Object { "$($_.Name):$($_.DiskMode)" }) -join '; '
    $actual = "TotalDisks={0}; NonPersistentCount={1}; NonPersistent={2}; Modes={3}" -f $totalDisks, $nonPersistentCount, $offenderNames, $modeSummary

    if ([string]::IsNullOrWhiteSpace($Row.Expected)) { $exp = 'Persistent' } else { $exp = $Row.Expected.Trim() }

    if ($exp -ieq 'Persistent') {
        if ($nonPersistentCount -eq 0) { $result = 'Pass' } else { $result = 'Fail' }
    } else {
        if ($actual -eq $exp) { $result = 'Pass' } else { $result = 'Fail' }
    }

    [pscustomobject]@{
        STIGID    = $Row.STIGID
        VID       = $Row.VID
        VM        = $VM.Name
        Check     = $Row.CheckType
        Expected  = $exp
        Actual    = $actual
        Result    = $result
        Severity  = $Row.Severity
        Timestamp = Get-Date
    }
}
