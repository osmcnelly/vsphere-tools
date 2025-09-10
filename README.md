# vSphere Tools

vSphere Tools is a scripted sollution that automates various VMWare STIG assessments.This tool is targeted towards cybersecurity professionals who frequently asses VMWare products(i,.e, vSphere ESXi, VCSA, and virtual machines) for security configuration compliant with DISA STIGs. 

## Authors

- [@osmcnelly](https://www.github.com/osmcnelly)


## Deployment

To deploy this project run

```bash
 git clone https://github.com/osmcnelly/vsphere-tools.git
```

Or download one of the published releases.
## Requirements
- Powershell 5.1 
- .NET Framework 4.7.2 or later
- PowerCLI module

### Steps for installing PowerCLI:
- Online install:
    1. To install all PowerCLI modules on an internet-connected computer, run the command:
       - `Install-Module VMware.PowerCLI -Scope CurrentUser`
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
