# Module for getting a list of VM names to work with. Option one gathers the names of every VM on the host.
# Option two allows the user to specify as few as one VM names.

function GetVMNames {
	$Serverlist = @()
	Do { 
		$vmName = Read-Host -Prompt "Enter the host name of the VM you'd like to pull settings for"
		if ($vmName -ne '') {$Serverlist += $vmName}
		$Response = Read-Host -Prompt "Would you like to add additional servers to this list? (y/n)"		
	} Until ($Response -eq 'n')
	return $Serverlist
}