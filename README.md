# vSphere Tools

vSphere Tools is a collection of PowerShell modules and scripts that automate DISA STIG assessments for VMware environments.  
It currently supports **ESXi 7/8**, with future plans to support **VCSA** and **virtual machines**, helping cybersecurity teams quickly evaluate compliance and generate standardized reports.

---

## ✨ Features
- Automated STIG checks against ESXi hosts and VMs (future capability)
- Version-aware CSV selectors (ESXi 7 vs 8)
- Dispatcher script to orchestrate checks
- JSON and CSV reporting with timestamps
- Modular design for easy extension (PowerCLI, SSH, reporting, etc.)

---

## 📦 Requirements
- PowerShell 5.1 (Windows) or PowerShell 7+  
- .NET Framework 4.7.2+  
- **VMware PowerCLI**

### Installing PowerCLI

**Online**
```powershell
    Install-Module VMware.PowerCLI -Scope CurrentUser
```

**Offline**
1. Download the PowerCLI ZIP from the VMware PowerCLI site and transfer it to the machine.  
2. Check the module search paths:
```powershell  
    $env:PSModulePath -split ';'
```
3. Extract the ZIP into one of those folders.  
4. Unblock the files:  
```powershell    
    Get-ChildItem -Recurse -File <path_to_extracted_PowerCLI> | Unblock-File
```
**Verify**
```powershell    
    Get-Module -Name VMware.PowerCLI* -ListAvailable
```
## 🚀 Quick Start

Clone the repository:
```bash
    git clone https://github.com/osmcnelly/vsphere-tools.git
    cd vsphere-tools
```
Run the dispatcher:
```powershell
    .\dispatcher.ps1
```
The script will connect to vSphere (if needed), run version-aware ESXi checks, and write reports to a timestamped folder.

## 🔀 Version-Aware CSV Selection

The dispatcher uses host version info to pick the correct CSV automatically:

- `EsxiStigChecks.esxi7.csv` → ESXi major version **7**  
- `EsxiStigChecks.esxi8.csv` → ESXi major version **8+**

## 📂 Repository Layout

- `Modules/` — Reusable PowerShell modules (SSH bootstrap, vSphere connect, reporting, check runners, etc.)
- `Checks/` — Helper scripts that perform various types of checks (advanced setting, SSH config, TPM mode, etc.)
- `dispatcher.ps1` — Orchestrates connection, runs checks, saves reports  
- `EsxiStigChecks.esxi7.csv` — STIG checks for ESXi 7  
- `EsxiStigChecks.esxi8.csv` — STIG checks for ESXi 8  
- `VMStigChecks.csv` — STIG checks for virtual machines  
- `vsphere-stig.psd1` — Module manifest

## 🧪 Output

You’ll get **both** JSON and CSV reports with a timestamped filename in the created reports directory.

Example JSON structure:
```json
{
  "STIGID": "ESXI-70-000041",
  "VID": "V-256405",
  "Check": "AdvancedSetting: UserVars.ESXiShellInteractiveTimeout",
  "Expected": "120",
  "Actual": "120",
  "Result": "Pass",
  "Severity": "medium"
}
```

## 🔧 Troubleshooting

- **Not connected to vCenter**  
  The dispatcher will detect this and initialize a PowerCLI session automatically.  

- **SSH checks fail**  
  Ensure the ESXi SSH service is enabled when running checks that require SSH access. 
  Note: Future capability: before establishing an SSH session, the script will check the SSH 
        service and turn it on if it is off. Once complete, the script will turn SSH off again.

- **Execution policy blocks scripts**  
  If you see errors about running scripts, set your policy:  
```powershell
      Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
## 🗺️ Roadmap

- Add VCSA-specific STIG checks  
- Support additional output formats (CKLB, CKL, XCCDF)  
- CI/CD integration and scheduled runs  
- Optional remediation helpers

## 👤 Author

Maintained by [@osmcnelly](https://github.com/osmcnelly)

## 📜 License

This project is licensed under the [MIT License](LICENSE).
