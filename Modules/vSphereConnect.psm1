# This module establishes a PowerCLI session with an ESXi or VCSA based off user input. 
# A PSCredential object is used to securely manage the login credentials.

function VSphereConnect {
	$global:server = Read-Host -Prompt 'Enter your vSphere or vCenter IP/FQDN'
	
	# Get and create login credentials as PS Object
	$vCUser = Read-Host -Prompt "Enter the VCSA or ESXi username"
	$vCPass = Read-Host -Prompt "Enter the password" -AsSecureString 
	$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCUser, $vCPass
	
	Connect-VIServer $server -Credential $Credentials -ErrorAction Inquire > $null

	$serverName = $global:DefaultVIServer | select -expandproperty name
	if(!$serverName){
		Write-Host ">>> ERROR: Unable to connect to $server." -ForegroundColor Red
		BREAK
	}
	else{		
		if ($serverName -eq $server){
			Write-Host ">>> Connected to $serverName" -ForegroundColor Cyan
		}
		else{
			Write-Host ">>> ERROR:Unable to connect to $server. No server match." -ForegroundColor Red
			BREAK
		}
	}
}