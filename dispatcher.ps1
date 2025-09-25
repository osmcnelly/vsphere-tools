# dispatcher.ps1

# Imports (kept from your current script)
Import-Module "$PSScriptRoot\Modules\PoshSshBootstrap.psm1"
Import-Module "$PSScriptRoot\Modules\SshSupport.psm1"
Import-Module "$PSScriptRoot\Modules\vSphereConnect.psm1"
Import-Module "$PSScriptRoot\Modules\CreateReportDir.psm1"
Import-Module "$PSScriptRoot\Modules\Invoke-EsxiStigChecks.psm1"
Import-Module "$PSScriptRoot\Modules\GetESXiVersion.psm1"

# New imports for VM path
$vmPickerPath = "$PSScriptRoot\Modules\GetVMNames.psm1"
$vmInvokerPath = "$PSScriptRoot\Modules\Invoke-VMStigChecks.psm1"
if (Test-Path $vmPickerPath)  { Import-Module $vmPickerPath  -ErrorAction SilentlyContinue }
if (Test-Path $vmInvokerPath) { Import-Module $vmInvokerPath -ErrorAction SilentlyContinue }

# Ensure VI connection
$serverList = $global:DefaultVIServer
if ($null -eq $serverList) {
    Write-Host ">>> Not connected to server."
    Write-Host ">>> Initializing PowerCLI Session. Please wait."
    vSphereConnect
}

# === User selects assessment scope ===
$mode = ''
$validModes = @(1,2)
while ([string]::IsNullOrEmpty($mode)) {
    $mode = Read-Host "Enter [1] to assess ESXi host(s), [2] to assess VM(s)"
    if ($mode -notin $validModes) {
        Write-Warning ("Your choice [{0}] is not valid. Choose 1 or 2." -f $mode)
        $mode = ''
        pause
    }
}

# --- Common helpers ---
function Write-CombinedReports {
    param(
        [Parameter(Mandatory)][array]$Results,
        [Parameter(Mandatory)][string]$Prefix # "EsxiStigReport" or "VmStigReport"
    )
    $reportDir = CreateReportDir
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $jsonReport = Join-Path $reportDir ("{0}_{1}.json" -f $Prefix, $timestamp)
    $csvReport  = Join-Path $reportDir ("{0}_{1}.csv"  -f $Prefix, $timestamp)

    $Results | ConvertTo-Json -Depth 8 | Out-File $jsonReport -Encoding UTF8
    $Results | Export-Csv -Path $csvReport -NoTypeInformation -Encoding UTF8
    Write-Host "Reports saved to $reportDir" -ForegroundColor Cyan

    return [pscustomobject]@{ Csv = $csvReport; Json = $jsonReport; Dir = $reportDir }
}

switch ($mode) {

    # =========================
    #     ESXi ASSESSMENT
    # =========================
    1 {
        # Your existing ESXi CSVs (unchanged)
        $csv7 = Join-Path $PSScriptRoot "EsxiStigChecks.esxi7.csv"
        $csv8 = Join-Path $PSScriptRoot "EsxiStigChecks.esxi8.csv"
        foreach ($p in @($csv7,$csv8)) {
            if (-not (Test-Path $p)) { throw "Required STIG CSV not found: $p" }
        }

        $vmHosts = Get-VMHost
        if (-not $vmHosts) { throw "No ESXi hosts returned by Get-VMHost." }

        # Use your module to resolve version per host
        $verInfo = $vmHosts.Name | Get-ESXiVersion

        # Group by Major version to select the right CSV
        $groups = $verInfo | Group-Object Major
        $allResults = @()

        foreach ($g in $groups) {
            $hostNames = $g.Group.Name
            $hostsInGroup = $vmHosts | Where-Object { $hostNames -contains $_.Name }
            if (-not $hostsInGroup) { continue }

            $csvPath = if ([int]$g.Name -ge 8) { $csv8 } else { $csv7 }

            Write-Host "Running STIG checks for ESXi major version $($g.Name) using '$(Split-Path $csvPath -Leaf)' on $($hostsInGroup.Count) host(s)..." -ForegroundColor Cyan
            $results = Invoke-EsxiStigChecks -CsvPath $csvPath -VMHost $hostsInGroup
            if ($results) { $allResults += $results }
        }

        Write-CombinedReports -Results $allResults -Prefix 'EsxiStigReport' | Out-Null
    }

    # =========================
    #       VM ASSESSMENT
    # =========================
    2 {
        if (-not (Get-Module -Name Invoke-VMStigChecks)) {
            if (-not (Test-Path $vmInvokerPath)) { throw "Invoke-VMStigChecks.psm1 not found at $vmInvokerPath" }
            Import-Module $vmInvokerPath -ErrorAction Stop
        }
        if (-not (Get-Module -Name GetVMNames)) {
            if (-not (Test-Path $vmPickerPath)) { throw "GetVMNames.psm1 not found at $vmPickerPath" }
            Import-Module $vmPickerPath -ErrorAction Stop
        }

        # VM CSVs chosen by ESXi host major version (per-VM basis)
        $vmCsv7 = Join-Path $PSScriptRoot "vSphere7VirtualMachine.csv"
        $vmCsv8 = Join-Path $PSScriptRoot "vSphere8VirtualMachine.csv"
        foreach ($p in @($vmCsv7,$vmCsv8)) {
            if (-not (Test-Path $p)) { Write-Warning "VM checklist CSV not found: $p" }
        }

        # VM selection flow (keeps your "all vs specify" UX)
        $vmChoice = ''
        $validVmChoices = @(1,2)
        while ([string]::IsNullOrEmpty($vmChoice)) {
            $vmChoice = Read-Host "Enter [1] to select all VMs; Enter [2] to specify VMs"
            if ($vmChoice -notin $validVmChoices) {
                Write-Warning ("Your choice [{0}] is not valid. Choose 1 or 2." -f $vmChoice)
                $vmChoice = ''
                pause
            }
        }

        $picked = @()
        switch ($vmChoice) {
            1 { $picked = Get-VM -Name * }
            2 { $picked = GetVMNames }    # typically returns strings (VM names)
        }
        if (-not $picked -or $picked.Count -eq 0) { throw "No VMs selected." }

        # --- Normalize to VM objects (handles strings or objects with a Name) ---
        $resolveErrors = @()
        $VMList = foreach ($item in $picked) {
            if ($item -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]) {
                $item
                continue
            }
            elseif ($item -is [string]) {
                try { Get-VM -Name $item -ErrorAction Stop } catch { $resolveErrors += $item }
                continue
            }
            elseif ($item | Get-Member -Name Name -MemberType NoteProperty,Property -ErrorAction SilentlyContinue) {
                try { Get-VM -Name $item.Name -ErrorAction Stop } catch { $resolveErrors += $item.Name }
                continue
            }
            else {
                $resolveErrors += ($item | Out-String)
            }
        }

        if ($resolveErrors.Count -gt 0) {
            Write-Warning ("Could not resolve the following VM(s): {0}" -f ($resolveErrors -join ', '))
        }
        if (-not $VMList -or $VMList.Count -eq 0) { throw "No resolvable VM objects after selection." }

        # Resolve ESXi versions for the VM hosts (now safe; VM objects have .VMHost)
        $vmHostsForVMs = $VMList | Select-Object -ExpandProperty VMHost -Unique
        if (-not $vmHostsForVMs) { throw "Could not resolve VMHost for selected VMs." }

        $verInfo = ($vmHostsForVMs | Select-Object -ExpandProperty Name) | Get-ESXiVersion
        if (-not $verInfo) { throw "Get-ESXiVersion did not return version info for VM hosts." }

        # Group VMs by their backing ESXi host major version
        $allResults = @()
        $majors = ($verInfo | Group-Object Major)

        foreach ($m in $majors) {
            $major = [int]$m.Name
            $hostNamesForMajor = $m.Group.Name
            $vmsInGroup = $VMList | Where-Object { $hostNamesForMajor -contains $_.VMHost.Name }
            if (-not $vmsInGroup) { continue }

            $csvPath = if ($major -ge 8) { $vmCsv8 } else { $vmCsv7 }
            if (-not (Test-Path $csvPath)) {
                $fallback = Read-Host "CSV for VM checks (major $major) not found. Enter full path to CSV"
                if (-not (Test-Path $fallback)) { throw "Provided CSV path not found: $fallback" }
                $csvPath = $fallback
            }

            Write-Host "Running VM checks for ESXi major version $major using '$(Split-Path $csvPath -Leaf)' on $($vmsInGroup.Count) VM(s)..." -ForegroundColor Cyan
            $results = Invoke-VMStigChecks -CsvPath $csvPath -VMList $vmsInGroup
            if ($results) { $allResults += $results }
        }

        Write-CombinedReports -Results $allResults -Prefix 'VmStigReport' | Out-Null
    }
}

# Clean up SSH sessions (kept)
if (Get-Command -Name Close-EsxiSshSessions -ErrorAction SilentlyContinue) {
    Close-EsxiSshSessions
    Write-Host "Closed SSH sessions" -ForegroundColor DarkCyan
}
