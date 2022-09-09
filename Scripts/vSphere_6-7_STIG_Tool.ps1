$scriptdir = $PSScriptRoot
Import-Module $scriptdir\..\modules\vSphereConnect
Import-Module $scriptdir\..\modules\GetVMNames

$serverList = $global:DefaultVIServer

if($null -eq $serverList){
	Write-Host ">>> Not connected to server."
	Write-Host ">>> Initializing PowerCLI Session. Please wait."
	VSphereConnect
}

# Variables
$Date = Get-Date
$Datefile = ( $Date ).ToString("yyyy-MM-dd-hhmmss")
$ErrorActionPreference = "SilentlyContinue"
$VMList = @()
$ParentDir = (Get-Item $scriptdir).parent 
$csvPath = Join-Path $ParentDir -ChildPath "\Reports\VSPHERE_REPORT_$Datefile.csv"

# Variable to Change
$CreateCSV = "yes"
$GridView = "no"
$FileCSV = New-Item -Type File -Path \..\$csvPath

# Array of settings to check on VM
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
$vmChoice = Read-Host -Prompt "Enter [1] to select all VMs. Enter [2] to specify VMs"
Switch ($vmChoice){
	1 {$VMList += Get-VM -Name cis*}
	2 {$VMList = GetVMNames}
}

# Gather settings and write them to the CSV file
Write-Host "Gathering VM Settings"

$Settings.GetEnumerator() | ForEach-Object {
	$vid = $($_.Key)
	foreach($VM in $VMList){
		$report = Get-VM $VM | Get-AdvancedSetting -name $($_.Value) | `
		Select-Object @{N="VID";E={$vid}},@{N='VM';E={$VM}},Name,Value,VID

		# If setting returns null, update the csv to reflect that
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




