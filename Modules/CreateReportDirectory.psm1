function CreateReportDir {
    $scriptdir = $PSScriptRoot
    $ParentDir = (Get-Item $scriptdir).parent 
    $ReportPath = Join-Path $ParentDir -ChildPath "\Reports"
	
    if (!(Test-Path -PathType Container -Path \..\$ReportPath)){
		New-Item -Path ..\ -Name "Reports" -ItemType Directory | Out-Null 
	}
}
