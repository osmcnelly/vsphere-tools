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
$ESXiList = @()
$csvPath = Join-Path $ParentDir -ChildPath "\Reports\VSPHERE_ESXI_REPORT_$Datefile.csv"

# Create empty CSV report
$FileCSV = New-Item -Type File -Path \..\$csvPath

# Variable to Change
$CreateCSV = "yes"
$GridView = "no"

# Ordered hashtable of settings to check on ESXi. Each setting's key is its respective vuln ID on the STIG checklist
$settings = [ordered]@{
    'V-239259' = "DCUI.Access"; 'V-239261' = "Syslog.global.logHost";
    'V-239262' = "Security.AccountLockFailures"; 'V-239263' = "Annotations.WelcomeMessage";
    'V-239264' = "Config.Etc.issue"; 'V-239265' = "Config.Etc.issue";
    'V-239285' = "Config.HostAgent.log.level"; 'V-239286' = "Security.PasswordQualityControl";
    'V-239287' = "Security.PasswordHistory"; 'V-239289' = "Config.HostAgent.plugins.solo.enableMob";
    'V-239294' = "Config.HostAgent.plugins.hostsvc.esxAdminsGroup"; 'V-239296' = "serVars.ESXiShellInteractiveTimeOut";
    'V-239297' = "UserVars.ESXiShellTimeOut"; 'V-239298' = "UserVars.DcuiTimeOut";
    'V-239309' = "Mem.ShareForceSalting"; 'V-239312' = "Net.BlockGuestBPDU";
    'V-239316' = "Net.DVFilterBindIpAddress"; 'V-239326' = "UserVars.ESXiVPsDisabledProtocols";
    'V-239329' = "UserVars.SuppressShellWarning"; 'V-239330' = "Syslog.global.logHost"
}

# Gather settings and write them to the CSV file
Write-Host "Gathering ESXi Settings"

# Using 'Get-AdvancedSetting' to gather the settings for the ESXi, then outputting the results to the CSV report
$Settings.GetEnumerator() | ForEach-Object {
	$vid = $($_.Key)
	foreach($ESXi in $ESXiList){
		$report = Get-VMHost $ESXi | Get-AdvancedSetting -name $($_.Value) |`
		 Select-Object @{N="VID";E={$vid}},@{N='Host';E={$ESXi}},Name,Value

		# If setting returns null, update the csv to reflect that instead of dropping the $null value
		if (!$report){ 
			New-Object -TypeName PSCustomObject -Property @{
			VID = $($_.Key)
			Host = $ESXi
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

$ESXiIP = ""
$ESXiIP = Read-Host -Prompt "Please entire the ESXi IP"

# Use SCP to transfer the script to the ESXi
scp $scriptdir\..\configcheck.sh root@ESXiIP:/configcheck.sh

# Run shell script via ssh
ssh -t root@$ESXiIP 'bash /configcheck.sh'