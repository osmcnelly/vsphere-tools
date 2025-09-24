# vSphere Tools

vSphere Tools is a collection of PowerShell modules and scripts that automate DISA STIG assessments for VMware environments.  
It supports **ESXi 7/8**, **VCSA**, and **virtual machines**, helping cybersecurity teams quickly evaluate compliance and generate standardized reports.

---

## ✨ Features
- Automated STIG checks against ESXi hosts and VMs
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
    Install-Module VMware.PowerCLI -Scope CurrentUser

**Offline**
1. Download the PowerCLI ZIP from the VMware PowerCLI site and transfer it to the machine.  
2. Check the module search paths:  
    $env:PSModulePath -split ';'
3. Extract the ZIP into one of those folders.  
4. Unblock the files:  
    Get-ChildItem -Recurse -File <path_to_extracted_PowerCLI> | Unblock-File

**Verify**
    Get-Module -Name VMware.PowerCLI* -ListAvailable

## 🚀 Quick Start

Clone the repository:
    git clone https://github.com/osmcnelly/vsphere-tools.git
    cd vsphere-tools

Run the dispatcher:
    .\dispatcher.ps1

The script will connect to vSphere (if needed), run version-aware ESXi checks, and write reports to a timestamped folder.

## 🔀 Version-Aware CSV Selection

The dispatcher uses host version info to pick the correct CSV automatically:

- `EsxiStigChecks.esxi7.csv` → ESXi major version **7**  
- `EsxiStigChecks.esxi8.csv` → ESXi major version **8+**

You can customize paths or filenames if you store the CSVs elsewhere.

## 📂 Repository Layout

- `dispatcher.ps1` — Orchestrates connection, runs checks, saves reports  
- `EsxiStigChecks.esxi7.csv` — STIG checks for ESXi 7  
- `EsxiStigChecks.esxi8.csv` — STIG checks for ESXi 8  
- `VMStigChecks.csv` — STIG checks for virtual machines  
- `Modules/` — Reusable PowerShell modules (SSH bootstrap, vSphere connect, reporting, check runners, etc.)  
- `vsphere-stig.psd1` — Module manifest

## 🧪 Output

You’ll get **both** JSON and CSV reports with a timestamped filename in the created reports directory.

Example JSON structure:
{
  "Host": "esx01.example.local",
  "RuleId": "ESXI-08-000123",
  "Status": "Fail",
  "FindingDetails": "SSH root login enabled",
  "Version": "8.0.2",
  "Build": "22380479"
}

## 🔧 Troubleshooting

- **Not connected to vCenter**  
  The dispatcher will detect this and initialize a PowerCLI session automatically.  

- **SSH checks fail**  
  Ensure the ESXi SSH service is enabled when running checks that require SSH access.  

- **Execution policy blocks scripts**  
  If you see errors about running scripts, set your policy:  
      Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

## 🗺️ Roadmap

- Add VCSA-specific STIG checks  
- Support additional output formats (CKLB, ARF)  
- CI/CD integration and scheduled runs  
- Optional remediation helpers

## 👤 Author

Maintained by [@osmcnelly](https://github.com/osmcnelly)

## 📜 License

This project is licensed under the [MIT License](LICENSE).
