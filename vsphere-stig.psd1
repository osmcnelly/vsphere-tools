@{
    RootModule        = 'vsphere-stig.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'b4a47c5e-89b3-4d44-8b1e-78e3b3f1c001'
    Author            = 'Obediyah McNelly'
    CompanyName       = 'NIWC-LANT'
    Description       = 'PowerCLI-driven STIG checks for VMware ESXi 7.x'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Invoke-EsxiStigChecks'
        'Get-EsxiStigCheck'
    )
    CmdletsToExport   = @()
    VariablesToExport = '*'
    AliasesToExport   = @()
}
