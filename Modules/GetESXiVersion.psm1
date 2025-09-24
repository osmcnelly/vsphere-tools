# GetESXiVersion.psm1
# Retrieves ESXi version/build details to drive STIG CSV selection

function Get-ESXiVersion {
    <#
    .SYNOPSIS
    Returns ESXi version/build info for one or more hosts.

    .DESCRIPTION
    Queries vCenter/ESXi via PowerCLI and emits an object per host with:
      Name, FullName, Version, Major, Minor, Patch, Build

    .PARAMETER VMHost
    One or more ESXi hostnames (or pipeline input). Also accepts -Name.

    .EXAMPLE
    Get-ESXiVersion -VMHost esx01,esx02

    .EXAMPLE
    'esx01','esx02' | Get-ESXiVersion

    .NOTES
    Use Major (and/or Minor/Patch) to choose your ESXi 7 vs 8 STIG CSV.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string[]]$VMHost
    )

    begin {
        # nothing to init
    }
    process {
        foreach ($hostName in $VMHost) {
            try {
                # Get-VMHost can return multiple (e.g., wildcard). Keep it robust.
                $vmHosts = Get-VMHost -Name $hostName -ErrorAction Stop
                foreach ($vh in $vmHosts) {
                    $verString = [string]$vh.Version
                    $verObj = $null
                    # Safely parse x.y.z (ignore weird vendor strings gracefully)
                    if (-not [version]::TryParse($verString, [ref]$verObj)) {
                        # Fallback: best-effort split
                        $parts = $verString -split '\.'
                        $maj = [int]($parts[0]  | Select-Object -First 1 -ErrorAction Ignore)
                        $min = [int]($parts[1]  | Select-Object -First 1 -ErrorAction Ignore)
                        $pat = [int]($parts[2]  | Select-Object -First 1 -ErrorAction Ignore)
                    } else {
                        $maj = $verObj.Major
                        $min = $verObj.Minor
                        $pat = $verObj.Build    # 3rd segment of x.y.z
                    }

                    # Friendly product string when available
                    $fullName = $null
                    try {
                        $view = $vh | Get-View -Property Config.Product -ErrorAction Stop
                        $fullName = $view.Config.Product.FullName
                    } catch {
                        $fullName = "ESXi $verString (build $($vh.Build))"
                    }

                    [pscustomobject]@{
                        Name     = $vh.Name
                        FullName = $fullName
                        Version  = $verString
                        Major    = $maj
                        Minor    = $min
                        Patch    = $pat
                        Build    = [string]$vh.Build  # keep as string; ESXi build IDs aren't pure integers semantically
                    }
                }
            } catch {
                Write-Error "Failed to query ESXi host '$hostName': $($_.Exception.Message)"
            }
        }
    }
}

Export-ModuleMember -Function Get-ESXiVersion
