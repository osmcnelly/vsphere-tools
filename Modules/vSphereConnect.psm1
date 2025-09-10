# This module establishes a PowerCLI session with an ESXi or VCSA based off user input. 
# A PSCredential object is used to securely manage the login credentials.

# VSphereConnect.psm1
# This module establishes a PowerCLI session with an ESXi or VCSA based off user input. 
# A PSCredential object is used to securely manage the login credentials.

function vSphereConnect {
    $global:server = Read-Host -Prompt 'Enter your vSphere or vCenter IP/FQDN'
    
    # Get and create login credentials as PSCredential object
    $vCUser = Read-Host -Prompt "Enter the VCSA or ESXi username"
    $vCPass = Read-Host -Prompt "Enter the password" -AsSecureString 
    $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCUser, $vCPass
    
    Connect-VIServer $server -Credential $Credentials -ErrorAction Inquire > $null

    $serverName = $global:DefaultVIServer | Select-Object -ExpandProperty Name
    if (!$serverName) {
        Write-Host ">>> ERROR: Unable to connect to $server." -ForegroundColor Red
        return [PSCustomObject]@{
            Server = $server
            Status = "Failed"
        }
    }
    else {        
        if ($serverName -eq $server) {
            Write-Host ">>> Connected to $serverName" -ForegroundColor Cyan
            return [PSCustomObject]@{
                Server = $serverName
                Status = "Connected"
            }
        }
        else {
            Write-Host ">>> ERROR: Unable to connect to $server. No server match." -ForegroundColor Red
            return [PSCustomObject]@{
                Server = $server
                Status = "Failed"
            }
        }
    }
}

# Export-ModuleMember -Function vSphereConnect
