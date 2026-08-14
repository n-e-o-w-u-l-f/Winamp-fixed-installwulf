param(
    [string]$SourceInstaller,
    [string]$ConfigFile = (Join-Path $PSScriptRoot '..\config\build-config.json')
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

if (-not $SourceInstaller) {
    $configForSource = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
    $SourceInstaller = $configForSource.source.path
}

$config = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
$payload = Join-Path $root 'build\payload'
$outDir = Join-Path $root 'build\output'
$manifest = Join-Path $root 'build\payload-manifest.json'
$installerName = $config.project.installerFileName
$outFile = Join-Path $outDir $installerName

$sourcePath = Join-Path $root $SourceInstaller
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Configured source installer not found: $sourcePath"
}

Remove-Item -LiteralPath $payload -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $manifest -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

& (Join-Path $PSScriptRoot 'extract-winamp.ps1') -SourceInstaller $sourcePath -PayloadDirectory $payload -ConfigFile (Join-Path $root 'config\build-config.json')

$makensis = 'C:\Program Files (x86)\NSIS\makensis.exe'
if (-not (Test-Path -LiteralPath $makensis)) {
    $command = Get-Command makensis.exe -ErrorAction SilentlyContinue
    if ($command) { $makensis = $command.Source }
}
if (-not $makensis -or -not (Test-Path -LiteralPath $makensis)) { throw 'NSIS makensis.exe was not found.' }

$nsisVersion = (& $makensis /VERSION 2>&1 | Select-Object -Last 1).ToString().Trim()
Write-Host "NSIS: $nsisVersion"
if ($nsisVersion -ne $config.toolchain.nsis.version) {
    throw "NSIS version mismatch. Expected $($config.toolchain.nsis.version), got $nsisVersion."
}

$versionInclude = Join-Path $root 'build\installer-version.nsh'
@(
    "!define INSTALL_WULF_FILE_VERSION \"$($config.installerVersion.fileVersion)\""
    "!define INSTALL_WULF_DISPLAY_VERSION \"$($config.installerVersion.displayVersion)\""
) | Set-Content -LiteralPath $versionInclude -Encoding ascii

Push-Location $root
try {
    & $makensis '/V4' 'installer\Install-Wulf.nsi'
    if ($LASTEXITCODE -ne 0) { throw "NSIS failed: $LASTEXITCODE" }
    $built = Join-Path $root 'installer\Winamp_InstallWulf-fixed.exe'
    if (-not (Test-Path -LiteralPath $built)) { throw "Expected NSIS output was not created: $built" }
    Move-Item -LiteralPath $built -Destination $outFile -Force
} finally {
    Pop-Location
}

& (Join-Path $PSScriptRoot 'verify-installer.ps1') -Installer $outFile -ConfigFile $ConfigFile -PayloadDirectory $payload
Write-Host "BUILD OUTPUT: $outFile"
