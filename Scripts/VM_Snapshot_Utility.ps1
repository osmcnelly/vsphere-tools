$ScriptDir = $PSScriptRoot

# Import modules
Import-Module "$ScriptDir\..\modules\vSphereConnect"
Import-Module "$ScriptDir\..\modules\GetVMNames"
Import-Module "$ScriptDir\..\modules\VMMaintenanceFunctions"

# Check if connected to the server
$connectedVIServers = $global:DefaultVIServer

if ($null -eq $connectedVIServers) {
    Write-Host ">>> Not connected to the server."
    Write-Host ">>> Initializing PowerCLI Session. Please wait."
    
    $Server, $Username, $Password = Get-VSphereCredentials
    Connect-VSphere -Server $Server -Username $Username -Password $Password
}

# Set ErrorActionPreference for the critical operation
$ErrorActionPreference = "Stop"

# Variables
$VMList = @()

# Get user's choice
$Choice = ''
$ValidChoiceList = 1, 2

while ([string]::IsNullOrEmpty($Choice)) {
    $Choice = Read-Host "Enter [1] to select all VMs. Enter [2] to specify VMs"

    if (![int]::TryParse($Choice, [ref]$null) -or $Choice -notin $ValidChoiceList) {
        Write-Warning "Your choice [$Choice] is not valid. Please try again & choose '1' or '2'."
        $Choice = ''
        pause
    }

    switch ($Choice) {
        1 { $VMList += Get-VM -Name *; break }
        2 { $VMList = Get-VMNames; break }
    }
}

# Create snapshots for each VM in the list
foreach ($vm in $VMList) {
    try {
        New-Snapshot -VMName $vm
    }
    catch {
        Write-Host "Error creating snapshot for $vm. $_" -ForegroundColor Red
        # Log the error or take additional actions if needed
    }
}