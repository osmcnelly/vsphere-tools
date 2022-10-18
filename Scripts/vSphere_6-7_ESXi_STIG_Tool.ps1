# This script retrieves the advanced setting specified by the vSphere 6.7 STIG released by DISA. 
# The script outputs the vm name, vulnerability ID, associated setting name, and setting status in CSV format.

# Relative Directory mapping
$scriptdir = $PSScriptRoot
$ParentDir = (Get-Item $scriptdir).parent 

Import-Module $scriptdir\..\modules\vSphereConnect
Import-Module $scriptdir\..\modules\CreateReportDirectory

CreateReportDir

$serverList = $global:DefaultVIServer

if ($null -eq $serverList){
	Write-Host ">>> Not connected to server." -ForegroundColor Red
	Write-Host ">>> Initializing PowerCLI Session. Please wait." -ForegroundColor Cyan
	VSphereConnect
}

# Variables
$Date = Get-Date
$Datefile = ($Date).ToString("yyyy-MM-dd-hhmmss")
$ErrorActionPreference = "SilentlyContinue"
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
    'V-239294' = "Config.HostAgent.plugins.hostsvc.esxAdminsGroup"; 'V-239296' = "UserVars.ESXiShellInteractiveTimeOut";
    'V-239297' = "UserVars.ESXiShellTimeOut"; 'V-239298' = "UserVars.DcuiTimeOut";
    'V-239309' = "Mem.ShareForceSalting"; 'V-239312' = "Net.BlockGuestBPDU";
    'V-239316' = "Net.DVFilterBindIpAddress"; 'V-239326' = "UserVars.ESXiVPsDisabledProtocols";
    'V-239329' = "UserVars.SuppressShellWarning"; 'V-239330' = "Syslog.global.logHost"
}

# Gather settings and write them to the CSV file
Write-Host "Gathering ESXi Settings" -ForegroundColor Yellow

# Using 'Get-AdvancedSetting' to gather the settings for the ESXi, then outputting the results to the CSV report
$Settings.GetEnumerator() | ForEach-Object {
	$vid = $($_.Key)
	$report = Get-VMHost | Get-AdvancedSetting -name $($_.Value) |`
	 Select-Object @{N="VID";E={$vid}},@{N='Host';E={$server}},Name,Value

	# If setting returns null, update the csv to reflect that instead of dropping the $null value
	if (!$report){ 
		New-Object -TypeName PSCustomObject -Property @{
		VID = $($_.Key)
		Host = $server
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

# A number of the 'Check Text' statements ask the ISSE to use grep via ssh to check configuration within the sshd_config file and 
# passwd file on the ESXi. The following lines use SCP to copy a shell script to the target ESXi, execute the script, then transfer
# the results back to the Reports folder. The ISSE can then compare the esxiconfigcheckresults.txt file to the STIG requirements. 

# Use SCP to transfer the script to the ESXi
Write-Host "`n>>> ENTER THE SSH PASSWORD TO TRANSFER CONFIGCHECK.SH TO THE TARGET HOST`n" -ForegroundColor Cyan
scp $scriptdir\..\configcheck.sh root@${server}:/configcheck.sh
Clear-Host

# Run shell script via ssh
Write-Host "`n>>> ENTER THE SSH PASSWORD TO RUN CONFIGCHECK.SH ON THE TARGET HOST`n" -ForegroundColor Cyan
ssh -t root@$server 'sh /configcheck.sh'
Clear-Host

# Transfer the results back to the Scripts folder
Write-Host "`n>>> ENTER THE SSH PASSWORD TO TRANSFER CONFIGCHECKRESULTS FROM THE TARGET HOST`n" -ForegroundColor Cyan
scp root@${server}:/configcheckout $scriptdir\..\Reports\grepresults.txt
Clear-Host

Write-Host "`nChecking remaining ESXi Settings" -ForegroundColor Yellow

# Non-standardized PowerCLI CKL Items
# These items are output to esxipowercliresults.txt. The ISSE can compare the results to the requirements listed in the STIG. 
$esxcli = Get-EsxCli -v2
$vmhost = Get-VMHost | Get-View
$lockdown = Get-View $vmhost.ConfigManager.HostAccessManager

$nonstandardsettings = [ordered]@{
	'V-239258' = Get-VMHost | Select-Object Name,@{N="Lockdown";E={$_.Extensiondata.Config.LockdownMode}};
	'V-239260' = $lockdown.QueryLockdownExceptions(); 
    'V-239267' = $esxcli.system.security.fips140.ssh.get.invoke(); 
	'V-239290' = Get-VMHost | Get-VMHostService | Where-Object {$_.Label -eq "SSH"}; 
	'V-239291' = Get-VMHost | Get-VMHostService | Where-Object {$_.Label -eq 'ESXi Shell'}; 'V-239307' = Get-VMHostSnmp | Select-Object *; 
	'V-239299' = $esxcli.system.coredump.partition.get.Invoke();
    'V-239299_2' = $esxcli.system.coredump.network.get.Invoke(); 	
	'V-239301' = Get-VMHost | Get-VMHostNTPServer; 
	'V-239301_2' = Get-VMHost | Get-VMHostService | Where-Object {$_.Label -eq "NTP Daemon"};
	'V-239302' = $esxcli.software.acceptance.get.Invoke();
	'V-239308' = Get-VMHost | Get-VMHostHba | Where-Object {$_.Type -eq 'iscsi'} | Select-Object AuthenticationProperties -ExpandProperty AuthenticationProperties;
    'V-239310' = Get-VMHost | Get-VMHostFirewallException | Where-Object {$_.Enabled -eq $true} | Select-Object Name,Enabled,@{N="AllIPEnabled";E={$_.ExtensionData.AllowedHosts.AllIP}}; 
	'V-239311' = Get-VMHostFirewallDefaultPolicy;
    'V-239313/314/315' = Get-VirtualSwitch | Get-SecurityPolicy;
    'V-239313/314/315_2' = Get-VirtualPortGroup | Get-SecurityPolicy; 
	'V-239317/318/319' = Get-VirtualPortGroup | Select-Object Name, VLanId
}

$nonstandardSettings.GetEnumerator() | ForEach-Object {
	$vid = $($_.Key)
	$report = $($_.Value)
	
	# Output returned setting values to text file
	Write-Output "------------------------------------------------------ `n${vid}:`n------------------------------------------------------ " | Out-File -append $scriptdir\..\Reports\esxipowercliresults.txt
	$report | Out-File -Append $scriptdir\..\Reports\esxipowercliresults.txt
}
