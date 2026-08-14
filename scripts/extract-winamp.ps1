param(
    [Parameter(Mandatory=$true)][string]$SourceInstaller,
    [Parameter(Mandatory=$true)][string]$PayloadDirectory
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $SourceInstaller)) { throw "Source installer not found: $SourceInstaller" }
$sevenZip = Get-Command 7z.exe -ErrorAction SilentlyContinue
if (-not $sevenZip -and (Test-Path 'C:\Program Files\7-Zip\7z.exe')) { $sevenZip = Get-Item 'C:\Program Files\7-Zip\7z.exe' }
if (-not $sevenZip -and (Test-Path 'C:\Program Files (x86)\7-Zip\7z.exe')) { $sevenZip = Get-Item 'C:\Program Files (x86)\7-Zip\7z.exe' }
if (-not $sevenZip) { throw '7z.exe is required on the build runner.' }
Remove-Item -LiteralPath $PayloadDirectory -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $PayloadDirectory -Force | Out-Null
& $sevenZip.Source x $SourceInstaller "-o$PayloadDirectory" -y
if ($LASTEXITCODE -ne 0) { throw "7-Zip extraction failed with exit code $LASTEXITCODE" }
$winamp = Join-Path $PayloadDirectory 'winamp.exe'
if (-not (Test-Path -LiteralPath $winamp)) { throw 'Expected winamp.exe was not found in extracted payload.' }
$info = [Diagnostics.FileVersionInfo]::GetVersionInfo($winamp)
Write-Host "Payload Winamp version: $($info.FileVersion)"
Write-Host "Payload files: $((Get-ChildItem $PayloadDirectory -Recurse -File).Count)"
