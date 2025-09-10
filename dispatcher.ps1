# Import required modules
Import-Module "$PSScriptRoot\Modules\PoshSshBootstrap.psm1"
Import-Module "$PSScriptRoot\Modules\SshSupport.psm1"
Import-Module "$PSScriptRoot\Modules\vSphereConnect.psm1"
Import-Module "$PSScriptRoot\Modules\CreateReportDir.psm1"
Import-Module "$PSScriptRoot\Modules\Invoke-EsxiStigChecks.psm1"

# Connect to vSphere
$serverList = $global:DefaultVIServer

if ($null -eq $serverList){
	Write-Host ">>> Not connected to server."
	Write-Host ">>> Initializing PowerCLI Session. Please wait."
	vSphereConnect
}

# Define CSV path
$csvPath = Join-Path $PSScriptRoot "EsxiStigChecks.csv"

# Run all checks (Invoke-EsxiStigChecks loops through CSV internally)
$results = Invoke-EsxiStigChecks -CsvPath $csvPath -VMHost (Get-VMHost)

# Save reports
$reportDir = CreateReportDir
$timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonReport = Join-Path $reportDir "EsxiStigReport_$timestamp.json"
$csvReport  = Join-Path $reportDir "EsxiStigReport_$timestamp.csv"

$results | ConvertTo-Json -Depth 5 | Out-File $jsonReport -Encoding UTF8
$results | Export-Csv -Path $csvReport -NoTypeInformation -Encoding UTF8

Write-Host "Reports saved to $reportDir" -ForegroundColor Cyan

# Clean up SSH sessions
if (Get-Command -Name Close-EsxiSshSessions -ErrorAction SilentlyContinue) {
	Close-EsxiSshSessions
	Write-Host "Closed SSH sessions" -ForegroundColor DarkCyan
}