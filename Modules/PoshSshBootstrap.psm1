# Bootstrap loader for vendored Posh-SSH
$modulesDir = $PSScriptRoot                          # ...\YourRepo\Modules
$poshDir    = Join-Path $modulesDir 'Posh-SSH'       # ...\Modules\Posh-SSH
$poshPsd1   = Join-Path $poshDir    'Posh-SSH.psd1'
$poshPsm1   = Join-Path $poshDir    'Posh-SSH.psm1'

if (-not (Test-Path $poshPsd1) -and -not (Test-Path $poshPsm1)) {
    throw "Vendored Posh-SSH not found at $poshDir. Expected Posh-SSH.psd1 or Posh-SSH.psm1."
}

# Optional: make the Modules dir itself discoverable for other vendored modules
if (($env:PSModulePath -split ';') -notcontains $modulesDir) {
    $env:PSModulePath = "$modulesDir;$env:PSModulePath"
}

# Some downloads are blocked by Windows—unblock to avoid load failures
Get-ChildItem $poshDir -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

# Import by explicit path to avoid discovery issues
if (Test-Path $poshPsd1) {
    Import-Module $poshPsd1 -Force -ErrorAction Stop
} else {
    Import-Module $poshPsm1 -Force -ErrorAction Stop
}
