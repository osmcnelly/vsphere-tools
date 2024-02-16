# This script retrieves the advanced setting specified by the vSphere 7.0 STIG released by DISA. 
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
    'V-256450' = "isolation.tools.copy.disable"; 'V-256451' = "isolation.tools.dnd.disable"; 
    'V-256452' = "isolation.tools.paste.disable"; 'V-256453' = "isolation.tools.diskShrink.disable"; 
    'V-256454' = "isolation.tools.diskwiper.disable"; 'V-256456' = "isolation.tools.hgfsServerSet.disable"; 
    'V-256462' = "RemoteDisplay.maxConnections"; 'V-256463' = "tools.setinfo.sizeLimit"; 
    'V-256464' = "isolation.device.connectable.disable"; 'V-256465' = "tools.guestlib.enableHostInfo"; 
    'V-256466' = "sched.mem.pshare.salt"; 'V-256467' = "ethernet*.filter*.name*"; 
    'V-256470' = "tools.guest.desktop.autolock"; 'V-256471' = "mks.enable3d";
    'V-256474' = "log.rotateSize"; 'V-256475' = "log.keepOld"; 
    'V-256476' = "pciPassthruX.present"
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

# Non-standardized PowerCLI CKL Items
# These items are output to vmpowercliresults.txt. The ISSE can compare the results to the requirements listed in the STIG. 

$NonStandardSettings = [ordered]@{
    'V-256457' = Get-VM | Get-FloppyDrive | Select-Object Parent, Name, ConnectionState
    'V-256458' = Get-VM | Get-CDDrive | Where-Object {$_.extensiondata.connectable.connected -eq $true} | Select-Object Parent,Name
    'V-256459' = Get-VM | Where-Object {$_.ExtensionData.Config.Hardware.Device.DeviceInfo.Label -match "parallel"}
    'V-256460' = Get-VM | Where-Object {$_.ExtensionData.Config.Hardware.Device.DeviceInfo.Label -match "serial"}
    'V-256461_1' = Get-VM | Where-Object {$_.ExtensionData.Config.Hardware.Device.DeviceInfo.Label -match "usb"}
    'V-256461_2' = Get-VM | Get-UsbDevice
    'V-256473' = Get-VM | Where-Object {$_.ExtensionData.Config.Flags.EnableLogging -ne "True"}
}

$NonStandardSettings.GetEnumerator() | ForEach-Object {
    $Vid = $_.Key
    $Report = $_.Value
    
    # Output returned setting values to text file
    Write-Output "------------------------------------------------------ `n${Vid}:`n------------------------------------------------------ " | Out-File -append "$ScriptDir\..\Reports\vmpowercliresults_$Datefile.txt"
    $Report | Out-File -Append "$ScriptDir\..\Reports\vmpowercliresults_$Datefile.txt"
}

# V-256455 check:
Write-Output "------------------------------------------------------ `nV-256455:`n------------------------------------------------------ " | Out-File -append "$ScriptDir\..\Reports\vmpowercliresults_$Datefile.txt"
foreach($VM in $SelectedVMs){
    $Report = Get-VM $VM | Get-HardDisk | Select-Object Parent, Name, Filename, DiskType, Persistence | Format-Table -AutoSize
    $Report | Out-File -Append "$ScriptDir\..\Reports\vmpowercliresults_$Datefile.txt"
}