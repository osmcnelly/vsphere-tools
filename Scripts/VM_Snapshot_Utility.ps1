$scriptdir = $PSScriptRoot
#$ParentDir = (Get-Item $scriptdir).parent 

Import-Module $scriptdir\..\modules\vSphereConnect
Import-Module $scriptdir\..\modules\GetVMNames
Import-Module $scriptdir\..\modules\VMMaintenanceFunctions

$serverList = $global:DefaultVIServer

if ($null -eq $serverList){
	Write-Host ">>> Not connected to server."
	Write-Host ">>> Initializing PowerCLI Session. Please wait."
	VSphereConnect
}

# Variables
#$Date = Get-Date
#$Datefile = ($Date).ToString("yyyy-MM-dd-hhmmss")
$ErrorActionPreference = "SilentlyContinue"
$VMList = @()

$Choice = ''
$ValidChoiceList = @(
	1
    2
)

while ([string]::IsNullOrEmpty($Choice)){
    $Choice = Read-Host "Enter [1] to select all VMs. Enter [2] to specify VMs"
    if ($Choice -notin $ValidChoiceList){
        Write-Warning ('Your choice [ {0} ] is not valid.' -f $Choice)
        Write-Warning '    Please try again & choose "1" or "2".'

        $Choice = ''
        pause
    }
    switch ($Choice){
		1 {$VMList += Get-VM -Name *; break}
		2 {$VMList = GetVMNames; break}
    }
}

forEach ($vm in $VMList)
	{createSnapshot($vm)
}