param(
    [Parameter(Mandatory=$true)][string]$Installer
)
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Installer -PathType Leaf)) {
    throw "Installer not found: $Installer"
}

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
Write-Host 'PE validation: PASS'

$version = [Diagnostics.FileVersionInfo]::GetVersionInfo($item.FullName)
Write-Host "Product: $($version.ProductName)"
Write-Host "File version: $($version.FileVersion)"
if ($version.ProductName -notmatch 'Install-Wulf') {
    throw "Unexpected ProductName: $($version.ProductName)"
}

$sevenZip = Get-Command 7z.exe -ErrorAction SilentlyContinue
if ($sevenZip) { $sevenZipPath = $sevenZip.Source }
if (-not $sevenZipPath -and (Test-Path 'C:\Program Files\7-Zip\7z.exe')) { $sevenZipPath = 'C:\Program Files\7-Zip\7z.exe' }
if (-not $sevenZipPath) { throw '7z.exe is required for installer structural validation.' }

& $sevenZipPath t $item.FullName -y | Out-Host
if ($LASTEXITCODE -ne 0) { throw "7-Zip structural test failed: $LASTEXITCODE" }
Write-Host 'Installer archive/SFX structural validation: PASS'
