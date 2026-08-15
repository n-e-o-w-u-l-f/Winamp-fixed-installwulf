param(
    [string]$SourceInstaller,
    [string]$ConfigFile = (Join-Path $PSScriptRoot '..\config\build-config.json'),
    [switch]$PayloadAlreadyExtracted,
    [string]$SevenZipPath = $null,
    [string]$NsisPath = $null
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$config = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
if (-not $SourceInstaller) {
    $SourceInstaller = $config.source.path
}

$payload = Join-Path $root 'build\payload'
$outDir = Join-Path $root 'build\output'
$installerName = $config.project.installerFileName
$outFile = Join-Path $outDir $installerName

if (-not (Test-Path -LiteralPath (Join-Path $root $SourceInstaller) -PathType Leaf)) {
    throw "Configured source installer not found: $(Join-Path $root $SourceInstaller)"
}

if (-not $PayloadAlreadyExtracted) {
    $extractArgs = @{
        SourceInstaller = (Join-Path $root $SourceInstaller)
        PayloadDirectory = $payload
        ConfigFile = $ConfigFile
    }
    if ($SevenZipPath) { $extractArgs.SevenZipPath = $SevenZipPath }
    & (Join-Path $PSScriptRoot 'extract-winamp.ps1') @extractArgs
}

if (-not (Test-Path -LiteralPath $payload -PathType Container)) {
    throw "Payload directory not found: $payload"
}
foreach ($requiredFile in $config.payload.requiredFiles) {
    $requiredPath = Join-Path $payload ($requiredFile -replace '/', '\\')
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required payload file is missing: $requiredFile"
    }
}

Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

if (-not $NsisPath) {
    $NsisPath = 'C:\Program Files (x86)\NSIS\makensis.exe'
    if (-not (Test-Path -LiteralPath $NsisPath)) {
        $command = Get-Command makensis.exe -ErrorAction SilentlyContinue
        if ($command) { $NsisPath = $command.Source }
    }
}
if (-not $NsisPath -or -not (Test-Path -LiteralPath $NsisPath)) { throw 'NSIS makensis.exe was not found.' }

$nsisVersion = (& $NsisPath /VERSION 2>&1 | Select-Object -Last 1).ToString().Trim()
Write-Host "NSIS: $nsisVersion"
if ($nsisVersion.TrimStart('v') -ne $config.toolchain.nsis.version) {
    throw "NSIS version mismatch. Expected $($config.toolchain.nsis.version), got $nsisVersion."
}

$versionInclude = Join-Path $root 'build\installer-version.nsh'
@(
    "!define INSTALL_WULF_FILE_VERSION " + [char]34 + $config.installerVersion.fileVersion + [char]34
    "!define INSTALL_WULF_DISPLAY_VERSION " + [char]34 + $config.installerVersion.displayVersion + [char]34
) | Set-Content -LiteralPath $versionInclude -Encoding ascii

Push-Location $root
try {
    & $NsisPath '/V4' 'installer\Install-Wulf.nsi'
    if ($LASTEXITCODE -ne 0) { throw "NSIS failed: $LASTEXITCODE" }
    $built = Join-Path $root 'installer\Winamp_InstallWulf-fixed.exe'
    if (-not (Test-Path -LiteralPath $built)) { throw "Expected NSIS output was not created: $built" }
    Move-Item -LiteralPath $built -Destination $outFile -Force
} finally {
    Pop-Location
}

Write-Host "BUILD OUTPUT: $outFile"
