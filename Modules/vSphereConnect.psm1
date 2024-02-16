# This module establishes a PowerCLI session with an ESXi or VCSA based off user input. 
# A PSCredential object is used to securely manage the login credentials.

function Connect-VSphere {
    param (
        [string]$Server,
        [string]$Username,
        [securestring]$Password
    )

    $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $Password

    try {
        Connect-VIServer $Server -Credential $Credentials -ErrorAction Stop
        Write-Host ">>> Connected to $Server" -ForegroundColor Cyan
    }
    catch {
        Write-Host ">>> ERROR: Unable to connect to $Server. $_" -ForegroundColor Red
    }
}

function Get-VSphereCredentials {
    $Server = Read-Host -Prompt 'Enter your vSphere or vCenter IP/FQDN'
    $Username = Read-Host -Prompt "Enter the VCSA or ESXi username"
    $Password = Read-Host -Prompt "Enter the password" -AsSecureString

    return $Server, $Username, $Password
}

# Example of usage
# $Server, $Username, $Password = Get-VSphereCredentials
# Connect-VSphere -Server $Server -Username $Username -Password $Password