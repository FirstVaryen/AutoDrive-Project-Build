# Builds a deploy-ready copy of the source for another org.
# The sandbox source names its test users in a few places (discount approval steps, dashboard
# "view as" users, the Case support address). Usernames are unique across all of Salesforce, so
# those names must be swapped for the target org's users before deploying.
#
# Usage (from the project folder):
#   1. Fill in scripts\deploy\target-users.csv (right-hand column = the target org's usernames).
#   2. powershell -File scripts\deploy\prepare-target.ps1
#   3. Deploy the folder it creates: deploy-build\force-app

$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$source = Join-Path $root 'force-app'
$build  = Join-Path $root 'deploy-build'
$map    = Import-Csv (Join-Path $PSScriptRoot 'target-users.csv')

$missing = $map | Where-Object { $_.target_username -like 'REPLACE_WITH*' -or [string]::IsNullOrWhiteSpace($_.target_username) }
if ($missing) {
    Write-Host 'Fill in these rows in scripts\deploy\target-users.csv first:' -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $($_.sandbox_username)" }
    exit 1
}

if (Test-Path $build) { Remove-Item $build -Recurse -Force }
New-Item -ItemType Directory -Path $build | Out-Null
Copy-Item $source -Destination $build -Recurse
Copy-Item (Join-Path $root 'sfdx-project.json') $build

$utf8 = New-Object System.Text.UTF8Encoding $false
$changed = 0
Get-ChildItem (Join-Path $build 'force-app') -Recurse -File -Include *.xml | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $new = $text
    foreach ($row in $map) { $new = $new.Replace($row.sandbox_username, $row.target_username) }
    if ($new -ne $text) { [IO.File]::WriteAllText($_.FullName, $new, $utf8); $changed++ }
}

$left = Get-ChildItem (Join-Path $build 'force-app') -Recurse -File -Include *.xml | Select-String -Pattern 'autodrive\.group3sb\.test' -List
if ($left) {
    Write-Host 'Sandbox names still present in:' -ForegroundColor Yellow
    $left | ForEach-Object { Write-Host "  $($_.Path)" }
} else {
    Write-Host "Ready: $changed files updated in deploy-build\force-app" -ForegroundColor Green
}
