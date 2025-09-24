# Import required modules
Import-Module "$PSScriptRoot\Modules\PoshSshBootstrap.psm1"
Import-Module "$PSScriptRoot\Modules\SshSupport.psm1"
Import-Module "$PSScriptRoot\Modules\vSphereConnect.psm1"
Import-Module "$PSScriptRoot\Modules\CreateReportDir.psm1"
Import-Module "$PSScriptRoot\Modules\Invoke-EsxiStigChecks.psm1"
Import-Module "$PSScriptRoot\Modules\GetESXiVersion.psm1"  # <-- NEW

# Connect to vSphere if needed
$serverList = $global:DefaultVIServer
if ($null -eq $serverList) {
    Write-Host ">>> Not connected to server."
    Write-Host ">>> Initializing PowerCLI Session. Please wait."
    vSphereConnect
}

# Define CSV paths (adjust names/locations if yours differ)
$csv7 = Join-Path $PSScriptRoot "EsxiStigChecks.esxi7.csv"
$csv8 = Join-Path $PSScriptRoot "EsxiStigChecks.esxi8.csv"

foreach ($p in @($csv7,$csv8)) {
    if (-not (Test-Path $p)) {
        throw "Required STIG CSV not found: $p"
    }
}

# Collect targets and version info
$vmHosts = Get-VMHost
if (-not $vmHosts) {
    throw "No ESXi hosts returned by Get-VMHost."
}

# Get Major/Minor/Patch/Build via your new module
$verInfo = $vmHosts.Name | Get-ESXiVersion

# Group hosts by Major version (7 vs 8, anything >=8 uses ESXi 8 CSV)
$groups = $verInfo | Group-Object Major

$allResults = @()

foreach ($g in $groups) {
    # Resolve host objects for this group from their names
    $hostNames = $g.Group.Name
    $hostsInGroup = $vmHosts | Where-Object { $hostNames -contains $_.Name }

    if (-not $hostsInGroup) { continue }

    # Choose CSV based on Major
    $csvPath = if ([int]$g.Name -ge 8) { $csv8 } else { $csv7 }

    Write-Host "Running STIG checks for ESXi major $($g.Name) using '$([IO.Path]::GetFileName($csvPath))' on $($hostsInGroup.Count) host(s)..." -ForegroundColor Cyan

    # Invoke checks for this subset (Invoke-EsxiStigChecks loops the CSV internally)
    $results = Invoke-EsxiStigChecks -CsvPath $csvPath -VMHost $hostsInGroup

    if ($results) { $allResults += $results }
}

# Save reports (combined)
$reportDir = CreateReportDir
$timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonReport = Join-Path $reportDir "EsxiStigReport_$timestamp.json"
$csvReport  = Join-Path $reportDir "EsxiStigReport_$timestamp.csv"

$allResults | ConvertTo-Json -Depth 5 | Out-File $jsonReport -Encoding UTF8
$allResults | Export-Csv -Path $csvReport -NoTypeInformation -Encoding UTF8

Write-Host "Reports saved to $reportDir" -ForegroundColor Cyan

# Clean up SSH sessions
if (Get-Command -Name Close-EsxiSshSessions -ErrorAction SilentlyContinue) {
    Close-EsxiSshSessions
    Write-Host "Closed SSH sessions" -ForegroundColor DarkCyan
}
