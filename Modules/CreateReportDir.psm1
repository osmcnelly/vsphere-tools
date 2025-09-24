function CreateReportDir {
    $scriptdir = $PSScriptRoot
    $ParentDir = (Get-Item $scriptdir).Parent.FullName
    $ReportPath = Join-Path $ParentDir "Reports"

    if (-not (Test-Path -Path $ReportPath)) {
        New-Item -Path $ReportPath -ItemType Directory | Out-Null
    }

    # Return the path so caller can use it
    return $ReportPath
}
