# vSphere Tools

This is a collection of modules and scripts for automating tasks with PowerCLI.

## Requirements
- Powershell 5.0 
- PowerCLI module

### Steps for installing PowerCLI:
- Online install:
    1. Doownlooad a version of PowerCLI compatible with your versioon of ESXi from [the PowerCLI homepage](https://developer.vmware.com/web/tool/vmware-powercli)
    2. To install all PowerCLI modules, run the command:
            ```
            Install-Module VMware.PowerCLI -Scope CurrentUser
            ```
- Offline install:
    1. Download the PowerCLI ZIP file from [the PowerCLI homepage](https://developer.vmware.com/web/tool/vmware-powercli) 
    and transfer the ZIP file to your local machine. 
    2. Check the PowerShell Module path by using the command: `$env:PSModulePath`.     
    3. Extract the contents of the ZIP file to one of the listed folders.
    4. Unblock the files by using the following commands:
        - `cd <path_to_powershell_modules_folder>` 
        - `Get-ChildItem * -Recurse | Unblock-File`   

You can verify that the PowerCLI module is available by using the following command: 
    `Get-Module -Name VMware.PowerCLI* -ListAvailable` 

## Usage
From a Powershell 5.0 terminal, specify the path to the script you would like to run. Scripts that generate reports 
or other output are written to create any necessary files and directories at runtime. 
