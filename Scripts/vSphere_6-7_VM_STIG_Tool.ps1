# This script retrieves the advanced settings specified by the vSphere 6.7 STIG released by DISA. 
# The script outputs the VM name, vulnerability ID, associated setting name, and setting status in CSV format.

# Relative Directory mapping
$ScriptDir = $PSScriptRoot

# Import custom modules
Import-Module "$ScriptDir\..\modules\vSphereConnect"
Import-Module "$ScriptDir\..\modules\GetVMNames"
Import-Module "$ScriptDir\..\modules\CreateReportDirectory"
Import-Module "$ScriptDir\..\modules\ExportToCSV"

# Create a new report directory
New-ReportDir

# Check if connected to the server
$ConnectedVIServers = $global:DefaultVIServer

if ($null -eq $ConnectedVIServers){
    Write-Host ">>> Not connected to the server."
    Write-Host ">>> Initializing PowerCLI Session. Please wait."
    $Server, $Username, $Password = Get-VSphereCredentials
    Connect-VSphere -Server $Server -Username $Username -Password $Password
}

# Variables
$Date = Get-Date
$Datefile = $Date.ToString("yyyy-MM-dd-hhmmss")
$ErrorActionPreference = "SilentlyContinue"

# Use more descriptive variable names
$SelectedVMs = @()
$CsvFilePath = Join-Path $PSScriptRoot -ChildPath "Reports\VSPHERE_VM_REPORT_$Datefile.csv"

# Create empty CSV report using Export-Csv
$CsvFile = New-Item -Type File -Path $CsvFilePath -Force

# Variable to Change
$ExportToCSV = $true
$GridView = $false

# Ordered hashtable of settings to check on VM. Each setting's key is its respective vuln ID on the STIG checklist
$Settings = [ordered]@{
    'V-239332' = "isolation.tools.copy.disable"; 'V-239333' = "isolation.tools.dnd.disable"; 
    'V-239334' = "isolation.tools.paste.disable"; 'V-239335' = "isolation.tools.diskShrink.disable"; 
    'V-239336' = "isolation.tools.diskwiper.disable"; 'V-239338' = "isolation.tools.hgfsServerSet.disable"; 
    'V-239344' = "RemoteDisplay.maxConnections"; 'V-239345' = "RemoteDisplay.vnc.enabled"; 
    'V-239346' = "tools.setinfo.sizeLimit"; 'V-239347' = "isolation.device.connectable.disable"; 
    'V-239348' = "tools.guestlib.enableHostInfo"; 'V-239349' = "sched.mem.pshare.salt"; 
    'V-239350' = "ethernet*.filter*.name*"; 'V-239353' = "tools.guest.desktop.autolock"; 
    'V-239354' = "mks.enable3d"
}

# Switch to choose between gathering settings for all VMs managed by the ESXi/VCSA or specific named VMs
$Choice = ''
$ValidChoiceList = @(1, 2)

while (-not $Choice){
    $Choice = Read-Host "Enter [1] to select all VMs. Enter [2] to specify VMs"
    
    if ($Choice -notin $ValidChoiceList){
        Write-Warning ('Your choice [ {0} ] is not valid.' -f $Choice)
        Write-Warning '    Please try again & choose "1" or "2".'
        $Choice = ''
        pause
    }
    
    switch ($Choice){
        1 {$SelectedVMs += Get-VM -Name *; break}
        2 {$SelectedVMs = Get-VMNames; break}
    }
}

# Gather settings and write them to the CSV file
Write-Host "Gathering VM Settings"

# Using 'Get-AdvancedSetting' to gather the settings for each VM, then outputting the results to the CSV report
$Settings.GetEnumerator() | ForEach-Object {
    $Vid = $_.Key
    foreach ($VM in $SelectedVMs){
        $Report = Get-VM $VM | Get-AdvancedSetting -Name $_.Value | `
            Select-Object @{N="VID";E={$Vid}},@{N='VM';E={$VM}},Name,Value

        # If setting returns null, update the csv to reflect that instead of dropping the $null value
        if (-not $Report){ 
            $NullSettingReport = [PSCustomObject]@{
                VID   = $Vid
                VM    = $VM
                Name  = $_.Value
                Value = "Setting not present"
            }
            Export-DataToCsv -Data $NullSettingReport -CsvFile $CsvFile
        }
        # Output returned setting values to the CSV
        if ($GridView -or $ExportToCSV){
			Export-DataToCsv -Data $Report -CsvFile $CsvFile
        }
    }
}