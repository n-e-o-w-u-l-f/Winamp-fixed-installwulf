param(
    [Parameter(Mandatory=$true)][string]$Installer
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Installer)) { throw "Installer not found: $Installer" }
$hash = Get-FileHash -LiteralPath $Installer -Algorithm SHA256
$size = (Get-Item -LiteralPath $Installer).Length
Write-Host "Installer: $Installer"
Write-Host "Size: $size bytes"
Write-Host "SHA256: $($hash.Hash)"
if ($size -lt 100000) { throw 'Installer is unexpectedly small.' }
# Basic PE marker validation
$bytes = [IO.File]::ReadAllBytes((Resolve-Path $Installer))
if ($bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { throw 'Output is not a PE executable.' }
Write-Host 'PE validation: PASS'
