function New-Snapshot {
    param (
        [string]$VMName
    )

    $Date = Get-Date
    $DateFormat = $Date.ToString("yyyy-MM-dd-HHmmss")

    try {
        Write-Host "Creating a new snapshot for $VMName"
        Get-VM $VMName | New-Snapshot -Name "$VMName Daily Snapshot $DateFormat" `
            -Confirm:$false -Description "Created with VM-Tools script" -Memory:$false -Quiesce:$false -RunAsync:$true
        Write-Host -ForegroundColor Green "`nDone."
    }
    catch {
        Write-Host -ForegroundColor Red -BackgroundColor Black "Error creating a new snapshot. $_"
        # Log the error or take additional actions if needed
    }
}

# Example of usage
# New-Snapshot -VMName "YourVMName"
