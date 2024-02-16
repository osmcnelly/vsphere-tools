# Module for getting a list of VM names to work with. Option one gathers the names of every VM on the host.
# Option two allows the user to specify as few as one VM names.

function Get-VMNames {
    $VMList = @()

    do {
        $VMName = Read-Host -Prompt "Enter the host name of the VM you'd like to pull settings for"
        if ($VMName -ne '') {
            # Add basic validation if needed
            $VMList += $VMName
        }

        $Response = Read-Host -Prompt "Do you want to add another VM to the list? (y/n)"
    } until ($Response -eq 'n')

    return $VMList
}

# Example of usage
# $SelectedVMs = Get-VMNames
# Write-Host "Selected VMs: $($SelectedVMs -join ', ')"
