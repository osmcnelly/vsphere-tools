# This script retrieves the advanced setting specified by the vSphere 6.7 STIG released by DISA. 
# The script outputs the vm name, vulnerability ID, associated setting name, and setting status in CSV format.

# Relative Directory mapping
$scriptdir = $PSScriptRoot
$ParentDir = (Get-Item $scriptdir).parent 

Import-Module $scriptdir\..\modules\vSphereConnect
Import-Module $scriptdir\..\modules\GetVMNames
Import-Module $scriptdir\..\modules\CreateReportDirectory

CreateReportDir

$serverList = $global:DefaultVIServer

if ($null -eq $serverList){
	Write-Host ">>> Not connected to server."
	Write-Host ">>> Initializing PowerCLI Session. Please wait."
	#VSphereConnect
}

# Variables
$Date = Get-Date
$Datefile = ($Date).ToString("yyyy-MM-dd-hhmmss")
#$ErrorActionPreference = "SilentlyContinue"
$VMList = @()
$csvPath = Join-Path $ParentDir -ChildPath "\Reports\VSPHERE_REPORT_$Datefile.csv"

# Create empty CSV report
$FileCSV = New-Item -Type File -Path \..\$csvPath

# Variable to Change
$CreateCSV = "yes"
$GridView = "no"

# Ordered hashtable of settings to check on VM. Each setting's key is its respective vuln ID on the STIG checklist
$settings = [ordered]@{
	'V-239332' = "isolation.tools.copy.disable"; 'V-239333' = "isolation.tools.dnd.disable"; 
	'V-239334' = "isolation.tools.paste.disable"; 'V-239335' = "isolation.tools.diskShrink.disable"; 
    'V-239336' = "isolation.tools.diskwiper.disable"; 'V-239338' = "isolation.tools.hgfsServerSet.disable"; 
	'V-239344' = "RemoteDisplay.maxConnections"; 'V-239345' = "RemoteDisplay.vnc.enabled"; 
	'V-239346' = "tools.setinfo.sizeLimit"; 'V-239347' = "isolation.device.connectable.disable"; 
	'V-239348' = "tools.guestlib.enableHostInf"; 'V-239349' = "sched.mem.pshare.salt"; 
	'V-239350' = "ethernet*.filter*.name*"; 'V-239353' = "tools.guest.desktop.autolock"; 
	'V-239354' = "mks.enable3d"
}

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
		$report = Get-VM $VM | Get-AdvancedSetting -name $($_.Value) |`
		 Select-Object @{N="VID";E={$vid}},@{N='VM';E={$VM}},Name,Value

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