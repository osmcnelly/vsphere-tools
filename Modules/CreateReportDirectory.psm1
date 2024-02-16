function New-ReportDir {
  $ScriptDir = $PSScriptRoot
  $ParentDir = (Get-Item $ScriptDir).Parent 
  $ReportPath = Join-Path $ParentDir -ChildPath "Reports"

  if (!(Test-Path -Path $ReportPath -PathType Container)) {
      New-Item -Path $ReportPath -ItemType Directory | Out-Null
      Write-Host "Report directory created: $ReportPath" -ForegroundColor Green
  }
  else {
      Write-Host "Report directory already exists: $ReportPath" -ForegroundColor Yellow
  }
}
