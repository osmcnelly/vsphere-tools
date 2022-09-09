function GetVMNames {
	$Serverlist = @()
	
	Do 
	{ 
		$vmName = Read-Host -Prompt "Enter the host name of the VM you'd like to pull settings for"
		if ($vmName -ne '') {$Serverlist += $vmName}
		$Response = Read-Host -Prompt "Would you like to add additional servers to this list? (y/n)"
		
	}
	Until ($Response -eq 'n')
	return $Serverlist
}