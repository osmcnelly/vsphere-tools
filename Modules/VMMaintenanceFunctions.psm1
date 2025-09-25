function createSnapshot($vm){
	$Date = Get-Date
	$Dateformat = ($Date).ToString("yyyy-MM-dd-hhmmss")
	try{
		Write-Host "Creating new snapshot for $vm"
		Get-VM $vm | New-Snapshot -name "$vm Daily Snapshot $Dateformat"`
		 -confirm:$false -description "Created with VM-Tools script" -memory:$false -quiesce:$false -RunAsync:$true
		Write-Host -foregroundcolor "Green" "`nDone."
	}
	catch{
		Write-Host -foregroundcolor RED -backgroundcolor BLACK`
		"Error creating new snapshot. See VCenter log for details."
	}
}