param(
    [Parameter(Mandatory = $true)][string]$Installer,
    [string]$ConfigFile = $null,
    [string]$PayloadDirectory,
    [string]$SevenZipPath = $null
)

if ([string]::IsNullOrWhiteSpace($ConfigFile)) { $ConfigFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\config\build-config.json' }

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Installer -PathType Leaf)) {
    throw "Installer not found: $Installer"
}
if (-not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) {
    throw "Build configuration not found: $ConfigFile"
}

$config = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
$item = Get-Item -LiteralPath $Installer
$hash = Get-FileHash -LiteralPath $Installer -Algorithm SHA256

Write-Host "Installer: $($item.FullName)"
Write-Host "Size: $($item.Length) bytes"
Write-Host "SHA256: $($hash.Hash)"

if ($item.Length -lt 100000) { throw 'Installer is unexpectedly small.' }

$bytes = [IO.File]::ReadAllBytes($item.FullName)
if ($bytes.Length -lt 64 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) {
    throw 'Output is not a valid PE/MZ executable.'
}

$peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
if ($peOffset -lt 0 -or $peOffset + 4 -gt $bytes.Length) {
    throw 'Invalid PE header offset.'
}
$peSignature = [Text.Encoding]::ASCII.GetString($bytes, $peOffset, 4)
if ($peSignature -ne 'PE' + [char]0 + [char]0) {
    throw 'MZ header exists, but PE signature is invalid.'
}
Write-Host 'PE validation: PASS'

$version = [Diagnostics.FileVersionInfo]::GetVersionInfo($item.FullName)
Write-Host "Product: $($version.ProductName)"
Write-Host "Product version: $($version.ProductVersion)"
Write-Host "File version: $($version.FileVersion)"

if ($version.ProductName -ne $config.project.name) {
    throw "Unexpected ProductName: $($version.ProductName)"
}
if ($version.FileVersion -ne $config.installerVersion.fileVersion) {
    throw "Unexpected FileVersion. Expected $($config.installerVersion.fileVersion), got $($version.FileVersion)."
}
if ($version.ProductVersion -ne $config.installerVersion.displayVersion) {
    throw "Unexpected ProductVersion. Expected $($config.installerVersion.displayVersion), got $($version.ProductVersion)."
}
Write-Host 'Version metadata validation: PASS'

if ($PayloadDirectory) {
    if (-not (Test-Path -LiteralPath $PayloadDirectory -PathType Container)) {
        throw "Payload directory not found: $PayloadDirectory"
    }
    foreach ($requiredFile in $config.payload.requiredFiles) {
        $requiredPath = Join-Path $PayloadDirectory ($requiredFile -replace '/', '\\')
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "Required payload file is missing: $requiredFile"
        }
    }
    $manifest = Join-Path (Split-Path $PayloadDirectory -Parent) 'payload-manifest.json'
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        throw "Payload manifest is missing: $manifest"
    }
    Write-Host 'Payload validation: PASS'
}

if (-not $SevenZipPath) {
    $sevenZip = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($sevenZip) { $SevenZipPath = $sevenZip.Source }
}
if (-not $SevenZipPath -and (Test-Path 'C:\Program Files\7-Zip\7z.exe')) { $SevenZipPath = 'C:\Program Files\7-Zip\7z.exe' }
if (-not $SevenZipPath -and (Test-Path 'C:\Program Files (x86)\7-Zip\7z.exe')) { $SevenZipPath = 'C:\Program Files (x86)\7-Zip\7z.exe' }
if (-not $SevenZipPath -or -not (Test-Path -LiteralPath $SevenZipPath -PathType Leaf)) { throw '7z.exe is required for installer structural validation.' }

$archiveTest = & $SevenZipPath t $item.FullName -y 2>&1
$archiveTest | Out-Host
if ($LASTEXITCODE -ne 0) { throw "7-Zip structural test failed: $LASTEXITCODE" }
Write-Host 'Installer archive/SFX structural validation: PASS'

$authenticode = Get-AuthenticodeSignature -LiteralPath $Installer
Write-Host "Installer Authenticode: $($authenticode.Status)"
if ($authenticode.SignerCertificate) {
    Write-Host "Installer signer: $($authenticode.SignerCertificate.Subject)"
    Write-Host "Installer signer thumbprint: $($authenticode.SignerCertificate.Thumbprint)"
}

$metadata = [ordered]@{
    schemaVersion = 1
    installer = [ordered]@{
        path = $item.Name
        sizeBytes = [int64]$item.Length
        sha256 = $hash.Hash.ToLowerInvariant()
        productName = $version.ProductName
        productVersion = $version.ProductVersion
        fileVersion = $version.FileVersion
        authenticodeStatus = [string]$authenticode.Status
        signerSubject = if ($authenticode.SignerCertificate) { $authenticode.SignerCertificate.Subject } else { $null }
        signerThumbprint = if ($authenticode.SignerCertificate) { $authenticode.SignerCertificate.Thumbprint } else { $null }
    }
    source = $config.source
}

$outputDirectory = Split-Path -Parent $Installer
$metadataPath = Join-Path $outputDirectory 'BUILD-METADATA.json'
$metadata | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $metadataPath -Encoding utf8
Write-Host "Build metadata: $metadataPath"
Write-Host 'Installer validation: PASS'
