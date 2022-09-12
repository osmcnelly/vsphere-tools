# This script retrieves the advanced setting specified by the vSphere 6.7 STIG released by DISA. 
# The script outputs the vm name, vulnerability ID, associated setting name, and setting status in CSV format.
# This branch is pending official release of Powershell 7.3. 
# Powershell 7.2's ConvertFrom-JSON -AsHashtable option creates a hashtable, disregarding the ordered format of 
# the JSON file. This is undesirable. PS 7.3 changes ConvertFrom-JSON -AsHashtable to treat the data as an
# ordered dictionary, preserving the formatting of the data within the JSON file. 

# Relative Directory mapping
$scriptdir = $PSScriptRoot
$ParentDir = (Get-Item $scriptdir).parent 
$AssetPath = Join-Path $ParentDir -ChildPath "\Assets"
Import-Module $scriptdir\..\modules\vSphereConnect
Import-Module $scriptdir\..\modules\GetVMNames
Import-Module $scriptdir\..\modules\CreateReportDirectory

CreateReportDir

$serverList = $global:DefaultVIServer

if ($null -eq $serverList){
	Write-Host ">>> Not connected to server."
	Write-Host ">>> Initializing PowerCLI Session. Please wait."
	VSphereConnect
}

# Variables
$Date = Get-Date
$Datefile = ($Date).ToString("yyyy-MM-dd-hhmmss")
$ErrorActionPreference = "SilentlyContinue"
$VMList = @()
$csvPath = Join-Path $ParentDir -ChildPath "\Reports\VSPHERE_REPORT_$Datefile.csv"

# Create empty CSV report
$FileCSV = New-Item -Type File -Path $csvPath

# Variable to Change
$CreateCSV = "yes"
$GridView = "no"

# Create an ordered hashtable of settings to check on VM by importing from the settings.json file. 
# Each setting's key is its respective vuln ID on the STIG checklist
$settings = [ordered]@{}
$settings = get-content -raw $assetpath\settings.json | convertfrom-json -ashashtable


# Switch to choose between gathering settings for all VMs managed by the ESXi/VCSA or specific named VMs
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

# Gather settings and write them to the CSV file
Write-Host "Gathering VM Settings"

# Using 'Get-AdvancedSetting' to gather the settings for each VM, then outputting the results to the CSV report
$Settings.GetEnumerator() | ForEach-Object {
	$vid = $($_.Key)
	foreach($VM in $VMList){
		$report = Get-VM $VM | Get-AdvancedSetting -name $($_.Value) | `
		Select-Object @{N="VID";E={$vid}},@{N='VM';E={$VM}},Name,Value,VID

		# If setting returns null, update the csv to reflect that instead of dropping the $null value
		if (!$report){ 
			New-Object -TypeName PSCustomObject -Property @{
			VID = $($_.Key)
			VM = $VM
			Name = $($_.Value)
			Value = "Setting not present"
			}| Export-CSV -LiteralPath $FileCSV -NoTypeInformation -append -UseCulture
		}
		# Output returned setting values to the CSV
		if ($GridView -eq "yes"){
			$report | Export-CSV -LiteralPath $FileCSV -NoTypeInformation -append -UseCulture
		}
		if ($CreateCSV -eq "yes"){
			$report | Export-CSV -LiteralPath $FileCSV -NoTypeInformation -append -UseCulture
		}
	}
}