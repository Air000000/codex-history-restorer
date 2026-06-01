param(
    [string] $OutputDir = (Join-Path $PSScriptRoot "..\dist"),
    [string] $Version = "0.2.0"
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$out = New-Item -ItemType Directory -Path $OutputDir -Force
$packageName = "codex-history-restorer-$Version"
$staging = Join-Path $out.FullName $packageName
$zip = Join-Path $out.FullName "$packageName.zip"

if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Path $staging -Force | Out-Null

$items = @(
    ".gitignore",
    "CHANGELOG.md",
    "CodexHistoryRestorer.Core.psm1",
    "LICENSE",
    "README.md",
    "Restore-CodexHistory-GUI.ps1",
    "Restore-CodexHistory.ps1",
    "run.bat",
    "run-cli.bat",
    "run-gui-hidden.vbs",
    "docs",
    "tools"
)

foreach ($item in $items) {
    $src = Join-Path $root $item
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination $staging -Recurse -Force
    }
}

$stagingItems = Get-ChildItem -LiteralPath $staging -Force
Compress-Archive -Path $stagingItems.FullName -DestinationPath $zip -Force
Write-Host "Created $zip"
