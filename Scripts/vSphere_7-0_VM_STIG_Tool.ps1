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
	VSphereConnect
}

# Variables
$Date = Get-Date
$Datefile = ($Date).ToString("yyyy-MM-dd-hhmmss")
$ErrorActionPreference = "SilentlyContinue"
$VMList = @()
$csvPath = Join-Path $ParentDir -ChildPath "\Reports\VSPHERE_VM_REPORT_$Datefile.csv"

# Create empty CSV report
$FileCSV = New-Item -Type File -Path \..\$csvPath

# Variable to Change
$CreateCSV = "yes"
$GridView = "no"

# Ordered hashtable of settings to check on VM. Each setting's key is its respective vuln ID on the STIG checklist
$settings = [ordered]@{
	'V-256450' = "isolation.tools.copy.disable"; 'V-256451' = "isolation.tools.dnd.disable"; 
	'V-256452' = "isolation.tools.paste.disable"; 'V-256453' = "isolation.tools.diskShrink.disable"; 
	'V-256454' = "isolation.tools.diskwiper.disable"; 'V-256456' = "isolation.tools.hgfsServerSet.disable"; 
	'V-256462' = "RemoteDisplay.maxConnections"; 'V-256463' = "tools.setinfo.sizeLimit"; 
	'V-256464' = "isolation.device.connectable.disable"; 'V-256465' = "tools.guestlib.enableHostInfo"; 
	'V-256466' = "sched.mem.pshare.salt"; 'V-256467' = "ethernet*.filter*.name*"; 
	'V-256470' = "tools.guest.desktop.autolock"; 'V-256471' = "mks.enable3d";
	'V-256474' = "log.rotateSize"; 'V-256475' = "log.keepOld"; 
	'V-256476' = "pciPassthruX.present"
}

# Switch to choose between gathering settings for all VMs managed by the ESXi/VCSA or specific named VMs
$Choice = ''
$ValidChoiceList = @(
	1
    2
)

while ([string]::IsNullOrEmpty($Choice)){
    $Choice = Read-Host "Enter [1] to Select-Object all VMs. Enter [2] to specify VMs"
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

# Non-standardized PowerCLI CKL Items
# These items are output to vmpowercliresults.txt. The ISSE can compare the results to the requirements listed in the STIG. 

$nonstandardsettings = [ordered]@{
	'V-256457' = Get-VM | Get-FloppyDrive | Select-Object Parent, Name, ConnectionState
	'V-256458' = Get-VM | Get-CDDrive | Where-Object {$_.extensiondata.connectable.connected -eq $true} | Select-Object Parent,Name
	'V-256459' = Get-VM | Where-Object {$_.ExtensionData.Config.Hardware.Device.DeviceInfo.Label -match "parallel"}
	'V-256460' = Get-VM | Where-Object {$_.ExtensionData.Config.Hardware.Device.DeviceInfo.Label -match "serial"}
	'V-256461_1' = Get-VM | Where-Object {$_.ExtensionData.Config.Hardware.Device.DeviceInfo.Label -match "usb"}
	'V-256461_2' = Get-VM | Get-UsbDevice
	'V-256473' = Get-VM | Where-Object {$_.ExtensionData.Config.Flags.EnableLogging -ne "True"}
}

$nonstandardSettings.GetEnumerator() | ForEach-Object {
	$vid = $($_.Key)
	$report = $($_.Value)
	
	# Output returned setting values to text file
	Write-Output "------------------------------------------------------ `n${vid}:`n------------------------------------------------------ " | Out-File -append $scriptdir"\..\Reports\vmpowercliresults_$Datefile.txt"
	$report | Out-File -Append $scriptdir"\..\Reports\vmpowercliresults_$Datefile.txt"
}

#V-256455 check:
Write-Output "------------------------------------------------------ `nV-256455:`n------------------------------------------------------ " | Out-File -append $scriptdir"\..\Reports\vmpowercliresults_$Datefile.txt"
foreach($VM in $VMList){
	$report = Get-VM $VM | Get-HardDisk | Select-Object Parent, Name, Filename, DiskType, Persistence | Format-Table -AutoSize
	$report | Out-File -Append $scriptdir"\..\Reports\vmpowercliresults_$Datefile.txt"
}