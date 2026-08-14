param(
    [string]$SourceInstaller = 'winamp\winamp_latest_installer.exe'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$payload = Join-Path $root 'build\payload'
$outDir = Join-Path $root 'build\output'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
& (Join-Path $PSScriptRoot 'extract-winamp.ps1') -SourceInstaller (Join-Path $root $SourceInstaller) -PayloadDirectory $payload
$makensis = 'C:\Program Files (x86)\NSIS\makensis.exe'
if (-not (Test-Path $makensis)) { $makensis = (Get-Command makensis.exe -ErrorAction SilentlyContinue).Source }
if (-not $makensis) { throw 'NSIS makensis.exe was not found.' }
Push-Location $root
try {
    & $makensis '/V4' 'installer\Install-Wulf.nsi'
    if ($LASTEXITCODE -ne 0) { throw "NSIS failed: $LASTEXITCODE" }
    $built = Join-Path $root 'installer\Winamp_InstallWulf-fixed.exe'
    if (-not (Test-Path $built)) { throw 'Expected NSIS output was not created.' }
    Move-Item $built (Join-Path $outDir 'Winamp_InstallWulf-fixed.exe') -Force
} finally { Pop-Location }
& (Join-Path $PSScriptRoot 'verify-installer.ps1') -Installer (Join-Path $outDir 'Winamp_InstallWulf-fixed.exe')
