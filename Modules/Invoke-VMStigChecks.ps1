# Invoke-VMStigChecks.ps1

# Load all Test-* scripts from Checks folder
$moduleRoot = $PSScriptRoot
$checkDir   = Join-Path (Split-Path $moduleRoot -Parent) "Checks"

if (Test-Path $checkDir) {
    Get-ChildItem -Path $checkDir -Filter *.ps1 | ForEach-Object { . $_.FullName }
}

function Invoke-VMStigChecks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CsvPath,

        # Accept either VM objects or names; keep it simple
        [Parameter(Mandatory)][object[]]$VMList
    )

    $rows = Import-Csv -Path $CsvPath
    $results = @()

    foreach ($vmItem in $VMList) {
        # Resolve to a VM object if a name/string was passed
        $vm = $vmItem
        if ($vmItem -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]) {
            $vm = Get-VM -Name $vmItem -ErrorAction Stop
        }

        foreach ($row in $rows) {
            try {
                switch ($row.CheckType) {
                    "AdvancedSetting"      { $results += Test-VMAdvancedSetting      -Row $row -VM $vm }
                    "vMotionEncryption"    { $results += Test-VMvMotionEncryption    -Row $row -VM $vm }
                    "FTEncryption"         { $results += Test-VMFTEncryption         -Row $row -VM $vm }
                    "VMLogging"            { $results += Test-VMLogging              -Row $row -VM $vm }
                    "VMPersistentDisk"     { $results += Test-VMPersistentDisk       -Row $row -VM $vm }
                    "UnneededFloppyDrives" { $results += Test-VMUnneededFloppyDrives -Row $row -VM $vm }
                    "UnneededDiskDrives"   { $results += Test-VMUnneededDiskDrives   -Row $row -VM $vm }
                    "UnneededParallelDevices" { $results += Test-VMUnneededParallelDevices -Row $row -VM $vm }
                    "UnneededSerialDevices"   { $results += Test-VMUnneededSerialDevices   -Row $row -VM $vm }
                    "UnneededUSBDevices"      { $results += Test-VMUnneededUSBDevices      -Row $row -VM $vm }

                    default {
                        $results += [PSCustomObject]@{
                            STIGID    = $row.STIGID
                            VID       = $row.VID
                            VM        = $vm.Name
                            Check     = $row.CheckType
                            CheckName = $row.CheckName
                            Expected  = $row.Expected
                            Expected2 = $row.Expected2
                            Actual    = $null
                            Result    = "Unsupported"
                            Severity  = $row.Severity
                            Timestamp = (Get-Date)
                        }
                    }
                }
            }
            catch {
                Write-Warning "Check failed for $($row.VID) on VM '$($vm.Name)': $_"
                $results += [PSCustomObject]@{
                    STIGID    = $row.STIGID
                    VID       = $row.VID
                    VM        = $vm.Name
                    Check     = $row.CheckType
                    CheckName = $row.CheckName
                    Expected  = $row.Expected
                    Expected2 = $row.Expected2
                    Actual    = "Error"
                    Result    = "Fail"
                    Severity  = $row.Severity
                    Timestamp = (Get-Date)
                }
            }
        }
    }

    return $results
}
